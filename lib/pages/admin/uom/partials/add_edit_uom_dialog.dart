import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/uom.dart';

class AddEditUomDialog extends StatefulWidget {
  final Map<String, dynamic>? uom;
  final VoidCallback onSaved;

  const AddEditUomDialog({
    super.key,
    this.uom,
    required this.onSaved,
  });

  @override
  State<AddEditUomDialog> createState() => _AddEditUomDialogState();
}

class _AddEditUomDialogState extends State<AddEditUomDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _uomController;
  bool _isSaving = false;
  String? _duplicateError;

  static const List<String> _commonUnits = [
    'Piece',
    'Pack',
    'Box',
    'Bottle',
    'Can',
    'Kg',
    'Gram',
    'Liter',
    'ml',
    'Sachet',
    'Tray',
    'Bundle',
  ];

  @override
  void initState() {
    super.initState();
    _uomController = TextEditingController(
      text: widget.uom != null ? (widget.uom!['uom'] ?? '') : '',
    );
  }

  @override
  void dispose() {
    _uomController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _uomController.text.trim();
    final int id = widget.uom != null ? ((widget.uom!['id'] as num?)?.toInt() ?? 0) : 0;

    setState(() => _isSaving = true);

    final exists = await Uom().uomExists(name, id > 0 ? id : null);
    if (exists) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _duplicateError = 'A unit of measure with this name already exists';
      });
      return;
    }

    try {
      await Uom().insertUom({
        'id': id,
        'uom': name,
      });

      widget.onSaved();
      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.uom == null
                ? 'Unit of measure created successfully'
                : 'Unit of measure updated successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save UOM: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.uom != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ThemeHelper.lightPrimary().withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.straighten_rounded,
                          color: ThemeHelper.primaryColor(),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit ? 'Edit Unit of Measure' : 'New Unit of Measure',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: ThemeHelper.textPrimary(),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isEdit ? 'Update packaging unit' : 'Define a packaging/selling unit',
                              style: TextStyle(
                                fontSize: 12,
                                color: ThemeHelper.textSecondary(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // UOM Name Field
                  TextFormField(
                    controller: _uomController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 30,
                    onChanged: (_) {
                      if (_duplicateError != null) {
                        setState(() => _duplicateError = null);
                      }
                    },
                    decoration: ThemeHelper.inputDecoration(
                      'Unit Name',
                      hint: 'e.g. Piece, Box, Pack, Kg, Bottle',
                      prefixIcon: const Icon(Icons.label_outline),
                    ).copyWith(
                      errorText: _duplicateError,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter a unit name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Common Suggestions
                  Text(
                    'QUICK SUGGESTIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _commonUnits.map((unit) {
                      return ActionChip(
                        label: Text(unit),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: ThemeHelper.textPrimary(),
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: ThemeHelper.backgroundColor(),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onPressed: () {
                          _uomController.text = unit;
                          if (_duplicateError != null) {
                            setState(() => _duplicateError = null);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeHelper.primaryColor(),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check, size: 18),
                        label: Text(
                          _isSaving
                              ? 'Saving...'
                              : (isEdit ? 'Update' : 'Save Unit'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
