import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/expense.dart';
import 'package:sales_management/services/user_session.dart';
import 'package:sales_management/utils/helper.dart';

class AddEditExpenseDialog extends StatefulWidget {
  final Map<String, dynamic>? expense;
  final VoidCallback onSaved;

  const AddEditExpenseDialog({
    super.key,
    this.expense,
    required this.onSaved,
  });

  @override
  State<AddEditExpenseDialog> createState() => _AddEditExpenseDialogState();
}

class _AddEditExpenseDialogState extends State<AddEditExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Supplies';
  bool _isSaving = false;
  Map<String, dynamic>? _currentUser;

  static const List<String> _categories = [
    'Supplies',
    'Utilities',
    'Food & Meals',
    'Rent',
    'Salaries',
    'Transportation',
    'Maintenance',
    'Miscellaneous',
  ];

  @override
  void initState() {
    super.initState();

    UserSession().loadUserSession().then((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });

    if (widget.expense != null) {
      _amountController.text = (widget.expense!['amount'] ?? '').toString();
      _descriptionController.text = widget.expense!['description'] ?? '';
      _selectedCategory = widget.expense!['category'] ?? 'Supplies';
      if (!_categories.contains(_selectedCategory)) {
        _selectedCategory = 'Miscellaneous';
      }

      final dateStr = widget.expense!['date'];
      if (dateStr != null) {
        try {
          _selectedDate = DateTime.parse(dateStr);
        } catch (_) {
          _selectedDate = DateTime.now();
        }
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ThemeHelper.primaryColor(),
              onPrimary: Colors.white,
              onSurface: ThemeHelper.textPrimary(),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount greater than 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dateStr = _selectedDate.toIso8601String().split('T')[0];
      final nowStr = DateTime.now().toIso8601String();

      final data = {
        'user_id': _currentUser?['id'] ?? 0,
        'amount': amount,
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'date': dateStr,
        'timestamp': nowStr,
      };

      if (widget.expense == null) {
        await Expense().insert(data);
      } else {
        data['id'] = widget.expense!['id'];
        await Expense().update(data);
      }

      widget.onSaved();
      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.expense == null
                ? 'Expense added successfully'
                : 'Expense updated successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save expense: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.expense != null;
    final formattedDate = Helper.formatDate(_selectedDate);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dialog Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: Colors.red.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEdit ? 'Edit Expense' : 'Add New Expense',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ThemeHelper.textPrimary(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Amount
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: ThemeHelper.inputDecoration(
                      'Amount',
                      hint: '0.00',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 14, right: 8),
                        child: Center(
                          widthFactor: 0,
                          child: Text(
                            '₱',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ThemeHelper.primaryColor(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter the amount';
                      }
                      if (double.tryParse(val.trim()) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Category
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: ThemeHelper.inputDecoration(
                      'Category',
                      prefixIcon: const Icon(Icons.category_outlined),
                    ),
                    items: _categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: ThemeHelper.inputDecoration(
                      'Description',
                      hint: 'e.g. Electricity bill, cleaning supplies...',
                      prefixIcon: const Icon(Icons.description_outlined),
                    ),
                    validator: (val) =>
                        (val == null || val.trim().isEmpty)
                            ? 'Please provide a description'
                            : null,
                  ),
                  const SizedBox(height: 14),

                  // Date Picker (Default Today)
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: ThemeHelper.inputDecoration(
                        'Date',
                        prefixIcon: const Icon(Icons.calendar_today_rounded),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (formattedDate == Helper.formatDate(DateTime.now()))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ThemeHelper.lightPrimary().withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Today',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: ThemeHelper.primaryColor(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Actions
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
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check, size: 18),
                        label: Text(
                          _isSaving
                              ? 'Saving...'
                              : (isEdit ? 'Update' : 'Save Expense'),
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
