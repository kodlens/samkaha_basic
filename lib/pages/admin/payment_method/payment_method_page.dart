import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/payment_method.dart';

class PaymentMethodPage extends StatefulWidget {
  const PaymentMethodPage({super.key});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  final PaymentMethod _model = PaymentMethod();
  late Future<List<Map<String, dynamic>>> _methodsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadMethods() {
    setState(() {
      _methodsFuture = _model.getPaymentMethods();
    });
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'e-wallet':
        return Icons.account_balance_wallet_rounded;
      case 'bank':
        return Icons.account_balance_rounded;
      case 'card':
        return Icons.credit_card_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type.toLowerCase()) {
      case 'e-wallet':
        return Colors.blue.shade700;
      case 'bank':
        return Colors.indigo.shade700;
      case 'card':
        return Colors.orange.shade800;
      default:
        return ThemeHelper.primaryColor();
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? method}) {
    final bool isEdit = method != null;
    final isCash = (method?['name']?.toString().toLowerCase() ?? '') == 'cash';
    final nameCtrl = TextEditingController(text: method?['name']?.toString() ?? '');
    String selectedType = method?['type']?.toString() ?? 'e-wallet';
    bool isActive = (method?['is_active'] as num?)?.toInt() != 0;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ThemeHelper.primaryColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isEdit ? Icons.edit_rounded : Icons.add_circle_outline_rounded,
                      color: ThemeHelper.primaryColor(),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit Payment Method' : 'New Payment Method',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: nameCtrl,
                          readOnly: isCash,
                          decoration: ThemeHelper.inputDecoration(
                            'Payment Method Name',
                            hint: 'e.g. GCash, Maya, BDO Unibank',
                            prefixIcon: const Icon(Icons.label_outline_rounded),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter method name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: selectedType,
                          isExpanded: true,
                          decoration: ThemeHelper.inputDecoration(
                            'Method Category / Type',
                            prefixIcon: const Icon(Icons.category_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'cash', child: Text('Cash')),
                            DropdownMenuItem(value: 'e-wallet', child: Text('E-Wallet (GCash, Maya, etc.)')),
                            DropdownMenuItem(value: 'bank', child: Text('Bank Transfer (BDO, BPI, etc.)')),
                            DropdownMenuItem(value: 'card', child: Text('Credit / Debit Card')),
                            DropdownMenuItem(value: 'other', child: Text('Other Digital Payment')),
                          ],
                          onChanged: isCash ? null : (val) {
                            if (val != null) setDialogState(() => selectedType = val);
                          },
                        ),
                        const SizedBox(height: 14),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: ThemeHelper.primaryColor(),
                          title: const Text('Active for POS Checkout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            isCash
                                ? 'Cash is always active by default'
                                : 'When active, cashiers can select this method in checkout',
                            style: TextStyle(fontSize: 11.5, color: ThemeHelper.textSecondary()),
                          ),
                          value: isCash ? true : isActive,
                          onChanged: isCash ? null : (val) => setDialogState(() => isActive = val),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: ThemeHelper.primaryColor()),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          final name = nameCtrl.text.trim();
                          final exists = await _model.nameExists(name, excludeId: method?['id']);
                          if (exists) {
                            if (dialogCtx.mounted) {
                              ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                SnackBar(content: Text('Payment method "$name" already exists.')),
                              );
                            }
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          if (isEdit) {
                            await _model.update({
                              'id': method['id'],
                              'name': name,
                              'type': selectedType,
                              'is_active': isActive ? 1 : 0,
                            });
                          } else {
                            await _model.insert({
                              'name': name,
                              'type': selectedType,
                              'is_active': isActive ? 1 : 0,
                            });
                          }

                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          _loadMethods();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isEdit ? 'Payment method updated' : 'Payment method added'),
                                backgroundColor: ThemeHelper.primaryColor(),
                              ),
                            );
                          }
                        },
                  child: Text(isSaving ? 'Saving...' : 'Save Method'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(Map<String, dynamic> method) async {
    final name = method['name']?.toString() ?? '';
    final id = (method['id'] as num?)?.toInt() ?? 0;

    if (name.toLowerCase() == 'cash') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The default "Cash" method cannot be deleted.')),
      );
      return;
    }

    final usage = await _model.countTransactions(name);

    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Delete Payment Method?'),
          content: Text(
            usage > 0
                ? 'Method "$name" is referenced in $usage recorded sales. It will be disabled instead of deleted to protect historical sales integrity.'
                : 'Are you sure you want to permanently delete "$name"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(ctx);
                final hardDeleted = await _model.delete(id, name);
                _loadMethods();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(hardDeleted ? 'Method deleted' : 'Method disabled'),
                      backgroundColor: hardDeleted ? Colors.red : Colors.orange.shade800,
                    ),
                  );
                }
              },
              child: Text(usage > 0 ? 'Disable Method' : 'Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKPI(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: ThemeHelper.cardBackground(),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: ThemeHelper.textSecondary(),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ThemeHelper.backgroundColor(),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _methodsFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final allMethods = snapshot.data ?? [];

          final filtered = allMethods.where((m) {
            if (_searchQuery.isEmpty) return true;
            final name = (m['name']?.toString() ?? '').toLowerCase();
            final type = (m['type']?.toString() ?? '').toLowerCase();
            return name.contains(_searchQuery) || type.contains(_searchQuery);
          }).toList();

          final int totalCount = allMethods.length;
          final int activeCount = allMethods.where((m) => (m['is_active'] as num?)?.toInt() != 0).length;
          final int epaymentCount = allMethods.where((m) => (m['type']?.toString().toLowerCase() ?? '') != 'cash').length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ThemeHelper.primaryColor(), const Color(0xFF2E6B3E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: ThemeHelper.primaryColor().withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    final titleSection = Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.payment_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment Methods',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Manage Cash & E-Payment Channels',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    final addButton = FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: ThemeHelper.primaryColor(),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      onPressed: () => _showAddEditDialog(),
                    );

                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          titleSection,
                          const SizedBox(height: 12),
                          addButton,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: titleSection),
                        const SizedBox(width: 12),
                        addButton,
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              // KPI Summary Row
              Row(
                children: [
                  _buildKPI('Total', '$totalCount', Icons.list_alt_rounded, Colors.grey.shade800),
                  const SizedBox(width: 8),
                  _buildKPI('Active', '$activeCount', Icons.check_circle_outline_rounded, ThemeHelper.primaryColor()),
                  const SizedBox(width: 8),
                  _buildKPI('E-Pay', '$epaymentCount', Icons.account_balance_wallet_outlined, Colors.blue.shade800),
                ],
              ),

              const SizedBox(height: 14),

              // Search Filter Bar
              Container(
                decoration: BoxDecoration(
                  color: ThemeHelper.cardBackground(),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search payment methods by name or type...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Methods List
              if (isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
              else if (filtered.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.payment_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        Text(
                          _searchQuery.isEmpty ? 'No payment methods found' : 'No methods match "$_searchQuery"',
                          style: TextStyle(color: ThemeHelper.textSecondary()),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...filtered.map((m) {
                  final String name = m['name']?.toString() ?? '';
                  final String type = m['type']?.toString() ?? 'cash';
                  final bool isCash = name.toLowerCase() == 'cash';
                  final bool isActive = (m['is_active'] as num?)?.toInt() != 0;
                  final Color typeColor = _colorForType(type);
                  final IconData typeIcon = _iconForType(type);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: ThemeHelper.cardBackground(),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive ? Colors.grey.shade200 : Colors.grey.shade300,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Icon Avatar
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(typeIcon, color: typeColor, size: 22),
                        ),
                        const SizedBox(width: 14),

                        // Title & Type Badge
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isActive ? ThemeHelper.textPrimary() : Colors.grey.shade500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isCash) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Default',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: typeColor.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      type.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: typeColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    isActive ? 'Active' : 'Disabled',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isActive ? Colors.green.shade700 : Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Active Toggle Switch
                        if (!isCash)
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: isActive,
                              activeThumbColor: ThemeHelper.primaryColor(),
                              onChanged: (val) async {
                                await _model.toggleActive(m['id'], val);
                                _loadMethods();
                              },
                            ),
                          ),

                        // Action Buttons
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: const Icon(Icons.edit_outlined, size: 19),
                          tooltip: 'Edit Method',
                          onPressed: () => _showAddEditDialog(method: m),
                        ),
                        if (!isCash)
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            icon: const Icon(Icons.delete_outline, size: 19, color: Colors.red),
                            tooltip: 'Delete Method',
                            onPressed: () => _confirmDelete(m),
                          ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
