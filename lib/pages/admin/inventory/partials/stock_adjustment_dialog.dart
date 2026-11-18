import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/adjustment.dart';

class StockAdjustmentDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final Map<String, dynamic>? currentUser;
  final VoidCallback onSaved;

  const StockAdjustmentDialog({
    super.key,
    required this.product,
    required this.currentUser,
    required this.onSaved,
  });

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();

  // 'IN' (Restock), 'OUT' (Damage/Loss/Return), 'AUDIT' (Physical Count Reconciliation)
  String _selectedAction = 'IN';
  bool _isSaving = false;

  final Map<String, List<String>> _quickReasons = {
    'IN': [
      'Supplier Delivery',
      'Stock Transfer',
      'Found Inventory',
      'Customer Return',
    ],
    'OUT': [
      'Damaged / Broken',
      'Expired / Spoilage',
      'Internal Use',
      'Inventory Discrepancy',
      'Supplier Return',
    ],
    'AUDIT': [
      'Physical Inventory Count',
      'Monthly Reconciliation',
      'Stock Correction',
    ],
  };

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  num get _currentStock => (widget.product['stock'] as num?) ?? 0;
  String get _unit => (widget.product['unit'] ?? 'PCS').toString().toUpperCase();

  num get _calculatedNewStock {
    final qty = double.tryParse(_quantityController.text.trim()) ?? 0;
    if (_selectedAction == 'IN') {
      return _currentStock + qty;
    } else if (_selectedAction == 'OUT') {
      return _currentStock - qty;
    } else {
      // AUDIT / SET
      return _quantityController.text.trim().isEmpty ? _currentStock : qty;
    }
  }

  void _applyQuickQuantity(int amount) {
    final currentQty = double.tryParse(_quantityController.text.trim()) ?? 0;
    final newQty = currentQty + amount;
    setState(() {
      _quantityController.text = newQty % 1 == 0 ? newQty.toInt().toString() : newQty.toString();
    });
  }

  Future<void> _submitAdjustment() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final qty = double.tryParse(_quantityController.text.trim()) ?? 0;
    if (qty <= 0 && _selectedAction != 'AUDIT') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Quantity must be greater than 0'),
          backgroundColor: ThemeHelper.error(),
        ),
      );
      return;
    }

    if (_selectedAction == 'OUT' && qty > _currentStock) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Negative Stock Warning'),
          content: Text(
            'Deducting $qty $_unit will reduce on-hand stock below zero (new stock: $_calculatedNewStock $_unit). Are you sure you want to proceed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ThemeHelper.error()),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Proceed', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    setState(() => _isSaving = true);

    try {
      final success = await Adjustment().insert({
        'user_id': widget.currentUser?['id'],
        'product_id': widget.product['id'],
        'action_status': _selectedAction,
        'quantity': qty,
        'current_stock': _currentStock,
        'reason': _reasonController.text.trim().isNotEmpty
            ? _reasonController.text.trim()
            : (_selectedAction == 'IN' ? 'Restock' : 'Stock Adjustment'),
      });

      if (!mounted) return;

      if (success) {
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stock adjusted for "${widget.product['name']}": $_currentStock -> $_calculatedNewStock $_unit',
            ),
            backgroundColor: ThemeHelper.primaryColor(),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save adjustment'),
            backgroundColor: ThemeHelper.error(),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: ThemeHelper.error(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.product['image_path']?.toString() ?? '';
    final hasImage = imagePath.isNotEmpty && File(imagePath).existsSync();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: ThemeHelper.cardBackground(),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Product Info (Wrapped & Ellipsis Protected)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 48,
                        height: 48,
                        color: ThemeHelper.primaryColor().withValues(alpha: 0.1),
                        child: hasImage
                            ? Image.file(File(imagePath), fit: BoxFit.cover)
                            : Center(
                                child: Text(
                                  (widget.product['name']?.toString() ?? 'P')
                                      .trim()
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: ThemeHelper.primaryColor(),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product['name'] ?? 'Adjust Inventory',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  'Current: $_currentStock $_unit',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                              if (widget.product['category'] != null &&
                                  widget.product['category'].toString().isNotEmpty)
                                Text(
                                  '• ${widget.product['category']}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: ThemeHelper.textSecondary(),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Adjustment Mode Selector
                Text(
                  'ADJUSTMENT TYPE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: ThemeHelper.textSecondary(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionTab(
                        title: 'Stock In',
                        subtitle: '+ Receiving',
                        icon: Icons.add_circle_outline,
                        action: 'IN',
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildActionTab(
                        title: 'Stock Out',
                        subtitle: '- Spoilage',
                        icon: Icons.remove_circle_outline,
                        action: 'OUT',
                        color: Colors.orange.shade800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildActionTab(
                        title: 'Audit / Set',
                        subtitle: '= Count',
                        icon: Icons.fact_check_outlined,
                        action: 'AUDIT',
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Quantity Input
                TextFormField(
                  controller: _quantityController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: ThemeHelper.inputDecoration(
                    _selectedAction == 'AUDIT'
                        ? 'Counted Stock ($_unit) *'
                        : 'Quantity to ${_selectedAction == 'IN' ? 'Add' : 'Deduct'} ($_unit) *',
                    hint: '0',
                    prefixIcon: Icon(
                      _selectedAction == 'IN'
                          ? Icons.add
                          : _selectedAction == 'OUT'
                              ? Icons.remove
                              : Icons.pin,
                      color: ThemeHelper.primaryColor(),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a quantity';
                    }
                    if (double.tryParse(val.trim()) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),

                // Quick Quantity Increment Chips (for Stock In)
                if (_selectedAction == 'IN') ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [5, 10, 25, 50, 100].map((qty) {
                      return ActionChip(
                        label: Text('+$qty'),
                        labelStyle: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700),
                        backgroundColor:
                            ThemeHelper.primaryColor().withValues(alpha: 0.08),
                        side: BorderSide(
                          color: ThemeHelper.primaryColor().withValues(alpha: 0.25),
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _applyQuickQuantity(qty),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 12),

                // Real-time Stock Calculation Preview Banner (Overflow-Proof)
                _buildNewStockBanner(),

                const SizedBox(height: 14),

                // Reason / Remarks
                Text(
                  'REASON / REMARKS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: ThemeHelper.textSecondary(),
                  ),
                ),
                const SizedBox(height: 6),

                // Quick Reason Suggestions
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: (_quickReasons[_selectedAction] ?? []).map((reason) {
                    final isSelected = _reasonController.text == reason;
                    return ChoiceChip(
                      label: Text(reason),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : ThemeHelper.textPrimary(),
                      ),
                      selected: isSelected,
                      selectedColor: ThemeHelper.primaryColor(),
                      backgroundColor: Colors.grey.withValues(alpha: 0.1),
                      side: BorderSide.none,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      onSelected: (selected) {
                        setState(() {
                          _reasonController.text = selected ? reason : '';
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _reasonController,
                  maxLines: 2,
                  decoration: ThemeHelper.inputDecoration(
                    'Notes / Details (Optional)',
                    hint: 'e.g. PO #1234, Batch #09',
                  ),
                ),
                const SizedBox(height: 18),

                // Save Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submitAdjustment,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      _isSaving ? 'Saving Adjustment...' : 'Confirm Adjustment',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeHelper.primaryColor(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTab({
    required String title,
    required String subtitle,
    required IconData icon,
    required String action,
    required Color color,
  }) {
    final isSelected = _selectedAction == action;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedAction = action;
          _reasonController.clear();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: isSelected ? color : Colors.grey.shade600),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? color : ThemeHelper.textPrimary(),
                ),
                maxLines: 1,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9.5,
                  color: isSelected
                      ? color.withValues(alpha: 0.8)
                      : ThemeHelper.textSecondary(),
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewStockBanner() {
    final newStock = _calculatedNewStock;
    final isNegative = newStock < 0;
    final isUnchanged = newStock == _currentStock;

    Color bannerColor = Colors.green;
    if (isNegative) {
      bannerColor = Colors.red;
    } else if (isUnchanged) {
      bannerColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isNegative ? Icons.warning_amber_rounded : Icons.sync_alt,
            size: 17,
            color: bannerColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Updated Stock:',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: bannerColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$_currentStock ➔ $newStock $_unit',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: bannerColor,
            ),
          ),
        ],
      ),
    );
  }
}
