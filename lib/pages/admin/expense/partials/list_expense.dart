import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/expense.dart';
import 'package:sales_management/pages/admin/expense/partials/add_edit_expense_dialog.dart';
import 'package:sales_management/utils/helper.dart';

enum ExpenseFilterPeriod { today, thisWeek, thisMonth, all, custom }

class ListExpense extends StatefulWidget {
  const ListExpense({super.key});

  @override
  State<ListExpense> createState() => _ListExpenseState();
}

class _ListExpenseState extends State<ListExpense> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ExpenseFilterPeriod _selectedPeriod = ExpenseFilterPeriod.today;
  DateTime _customDate = DateTime.now();

  Future<List<Map<String, dynamic>>>? _future;
  double _todayTotal = 0.0;
  double _filteredTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final today = await Expense().getTodayTotal();
    final listFuture = _fetchExpenses();
    final expenses = await listFuture;

    double sum = 0.0;
    for (final e in expenses) {
      sum += (e['amount'] as num?)?.toDouble() ?? 0.0;
    }

    if (mounted) {
      setState(() {
        _todayTotal = today;
        _filteredTotal = sum;
        _future = Future.value(expenses);
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchExpenses() async {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case ExpenseFilterPeriod.today:
        return await Expense().queryByDate(now);
      case ExpenseFilterPeriod.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return await Expense().queryByDateRange(startOfWeek, endOfWeek);
      case ExpenseFilterPeriod.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        return await Expense().queryByDateRange(startOfMonth, endOfMonth);
      case ExpenseFilterPeriod.custom:
        return await Expense().queryByDate(_customDate);
      case ExpenseFilterPeriod.all:
        return await Expense().queryAll();
    }
  }

  void _openAddEditExpense([Map<String, dynamic>? expense]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddEditExpenseDialog(
        expense: expense,
        onSaved: _refreshData,
      ),
    );
  }

  void _onTapDelete(Map<String, dynamic> expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text(
          'Are you sure you want to delete this expense of ${Helper.formatNumberWithPeso(expense['amount'])} for "${expense['description']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Expense().delete(expense['id']);
      _refreshData();
    }
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDate,
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
        _customDate = picked;
        _selectedPeriod = ExpenseFilterPeriod.custom;
      });
      _refreshData();
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'Utilities':
        return Icons.bolt;
      case 'Food & Meals':
        return Icons.restaurant;
      case 'Rent':
        return Icons.home_work_outlined;
      case 'Salaries':
        return Icons.payments_outlined;
      case 'Transportation':
        return Icons.directions_car_outlined;
      case 'Maintenance':
        return Icons.build_outlined;
      case 'Supplies':
        return Icons.inventory_2_outlined;
      default:
        return Icons.receipt_outlined;
    }
  }

  // ================= UI BUILDERS =================

  Widget _buildSummaryCards(bool isWide) {
    final todayCard = _summaryCard(
      title: "Today's Expenses",
      amount: _todayTotal,
      icon: Icons.calendar_today_rounded,
      iconColor: Colors.red.shade700,
      bgColor: Colors.red.shade50,
    );

    final filteredCard = _summaryCard(
      title: _selectedPeriod == ExpenseFilterPeriod.today
          ? "Today's Total"
          : _selectedPeriod == ExpenseFilterPeriod.thisWeek
              ? "This Week's Total"
              : _selectedPeriod == ExpenseFilterPeriod.thisMonth
                  ? "This Month's Total"
                  : _selectedPeriod == ExpenseFilterPeriod.custom
                      ? "Selected Date Total"
                      : "All Time Total",
      amount: _filteredTotal,
      icon: Icons.account_balance_wallet_outlined,
      iconColor: ThemeHelper.primaryColor(),
      bgColor: ThemeHelper.lightPrimary().withValues(alpha: 0.25),
    );

    if (isWide) {
      return Row(
        children: [
          Expanded(child: todayCard),
          const SizedBox(width: 14),
          Expanded(child: filteredCard),
        ],
      );
    }

    return Column(
      children: [
        todayCard,
        const SizedBox(height: 10),
        filteredCard,
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: ThemeHelper.textSecondary(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Helper.formatNumberWithPeso(amount),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: ThemeHelper.textPrimary(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('Today', ExpenseFilterPeriod.today),
          const SizedBox(width: 8),
          _filterChip('This Week', ExpenseFilterPeriod.thisWeek),
          const SizedBox(width: 8),
          _filterChip('This Month', ExpenseFilterPeriod.thisMonth),
          const SizedBox(width: 8),
          _filterChip('All Time', ExpenseFilterPeriod.all),
          const SizedBox(width: 8),
          ActionChip(
            onPressed: _pickCustomDate,
            avatar: const Icon(Icons.date_range, size: 16),
            label: Text(
              _selectedPeriod == ExpenseFilterPeriod.custom
                  ? Helper.formatDate(_customDate)
                  : 'Pick Date...',
            ),
            backgroundColor: _selectedPeriod == ExpenseFilterPeriod.custom
                ? ThemeHelper.primaryColor()
                : Colors.white,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _selectedPeriod == ExpenseFilterPeriod.custom
                  ? Colors.white
                  : ThemeHelper.textPrimary(),
            ),
            side: BorderSide(
              color: _selectedPeriod == ExpenseFilterPeriod.custom
                  ? ThemeHelper.primaryColor()
                  : Colors.grey.shade300,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, ExpenseFilterPeriod period) {
    final isSelected = _selectedPeriod == period;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      selectedColor: ThemeHelper.primaryColor(),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : ThemeHelper.textPrimary(),
      ),
      side: BorderSide(
        color: isSelected ? ThemeHelper.primaryColor() : Colors.grey.shade300,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (val) {
        if (val) {
          setState(() => _selectedPeriod = period);
          _refreshData();
        }
      },
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> item) {
    final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
    final category = item['category']?.toString() ?? 'Others';
    final description = item['description']?.toString() ?? '';
    final date = item['date']?.toString() ?? '';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ThemeHelper.backgroundColor(),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Icon(
                _getCategoryIcon(category),
                color: ThemeHelper.primaryColor(),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ThemeHelper.lightPrimary().withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: ThemeHelper.primaryColor(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 12,
                          color: ThemeHelper.textSecondary(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Helper.formatNumberWithPeso(amount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      color: ThemeHelper.primaryColor(),
                      onPressed: () => _openAddEditExpense(item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      color: Colors.red.shade400,
                      onPressed: () => _onTapDelete(item),
                    ),
                  ],
                ),
              ],
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 750;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Header & Add Button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expense Management',
                          style: TextStyle(
                            fontSize: isWide ? 22 : 18,
                            fontWeight: FontWeight.bold,
                            color: ThemeHelper.textPrimary(),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Track and manage store disbursements',
                          style: TextStyle(
                            fontSize: 12,
                            color: ThemeHelper.textSecondary(),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _openAddEditExpense(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeHelper.primaryColor(),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isWide ? 18 : 12,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        isWide ? 'Record Expense' : 'Add',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Summary Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildSummaryCards(isWide),
              ),

              // Search & Period Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() => _searchQuery = val.trim().toLowerCase());
                      },
                      decoration: InputDecoration(
                        hintText: 'Search expenses by description...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
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
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPeriodChips(),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Expenses List
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final list = snapshot.data ?? [];
                    final filtered = _searchQuery.isEmpty
                        ? list
                        : list.where((item) {
                            final desc = (item['description'] ?? '')
                                .toString()
                                .toLowerCase();
                            final cat = (item['category'] ?? '')
                                .toString()
                                .toLowerCase();
                            return desc.contains(_searchQuery) ||
                                cat.contains(_searchQuery);
                          }).toList();

                    if (filtered.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: _refreshData,
                        child: ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.3,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 54,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'No expenses recorded for this period',
                                      style: TextStyle(
                                        color: ThemeHelper.textSecondary(),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _refreshData,
                      child: isWide
                          ? GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 3.2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) =>
                                  _buildExpenseCard(filtered[index]),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) =>
                                  _buildExpenseCard(filtered[index]),
                            ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
