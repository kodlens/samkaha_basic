import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/expense.dart';
import 'package:sales_management/models/transaction.dart';
import 'package:sales_management/utils/helper.dart';

class TodaysSales extends StatefulWidget {
  const TodaysSales({super.key});

  @override
  State<TodaysSales> createState() => _TodaysSalesState();
}

class _TodaysSalesState extends State<TodaysSales> {
  late Future<Map<String, dynamic>> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _summaryFuture = _fetchTodaySummary();
  }

  Future<Map<String, dynamic>> _fetchTodaySummary() async {
    final breakdown = await Transaction().getTodaySalesBreakdown();
    final expense = await Expense().getTodayTotal();

    final totalSales = (breakdown['total_sales'] as num?)?.toDouble() ?? 0.0;
    final cashSales = (breakdown['cash_sales'] as num?)?.toDouble() ?? 0.0;
    final epaymentSales = (breakdown['epayment_sales'] as num?)?.toDouble() ?? 0.0;
    final txCount = (breakdown['tx_count'] as num?)?.toInt() ?? 0;
    final totalQty = (breakdown['total_qty'] as num?)?.toInt() ?? 0;
    final avgTicket = (breakdown['avg_ticket'] as num?)?.toDouble() ?? 0.0;

    // Cash on Hand is physical Cash Sales collected minus expenses
    final cashOnHand = cashSales - expense;
    // Net total is all sales minus expenses
    final netSales = totalSales - expense;

    return {
      'total_sales': totalSales,
      'cash_sales': cashSales,
      'epayment_sales': epaymentSales,
      'cash_on_hand': cashOnHand,
      'tx_count': txCount,
      'total_qty': totalQty,
      'avg_ticket': avgTicket,
      'expense': expense,
      'net_sales': netSales,
      'methods': breakdown['methods'] ?? [],
    };
  }

  Widget _miniStat({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: ThemeHelper.backgroundColor(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: ThemeHelper.textSecondary()),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: ThemeHelper.textSecondary(),
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: valueColor ?? ThemeHelper.textPrimary(),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final data = snapshot.data ?? {};

          final totalSales = (data['total_sales'] as num?)?.toDouble() ?? 0.0;
          final cashSales = (data['cash_sales'] as num?)?.toDouble() ?? 0.0;
          final epaymentSales = (data['epayment_sales'] as num?)?.toDouble() ?? 0.0;
          final cashOnHand = (data['cash_on_hand'] as num?)?.toDouble() ?? 0.0;
          final txCount = (data['tx_count'] as num?)?.toInt() ?? 0;
          final totalQty = (data['total_qty'] as num?)?.toInt() ?? 0;
          final avgTicket = (data['avg_ticket'] as num?)?.toDouble() ?? 0.0;
          final expense = (data['expense'] as num?)?.toDouble() ?? 0.0;
          final netSales = (data['net_sales'] as num?)?.toDouble() ?? 0.0;

          return Container(
            decoration: BoxDecoration(
              color: ThemeHelper.cardBackground(),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: ThemeHelper.lightPrimary().withValues(alpha: 0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: ThemeHelper.primaryColor().withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Banner: Gross Sales
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: ThemeHelper.lightPrimary().withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.payments_rounded,
                        color: ThemeHelper.primaryColor(),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Today's Gross Sales",
                                style: TextStyle(
                                  color: ThemeHelper.textSecondary(),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Live',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isLoading ? '...' : Helper.formatNumberWithPeso(totalSales),
                            style: TextStyle(
                              color: ThemeHelper.primaryColor(),
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ThemeHelper.backgroundColor(),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$txCount Transactions',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$totalQty Items',
                            style: TextStyle(
                              fontSize: 11,
                              color: ThemeHelper.textSecondary(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Cash on Hand vs E-Payments Dual Banner
                Row(
                  children: [
                    // Cash on Hand Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ThemeHelper.primaryColor().withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: ThemeHelper.primaryColor().withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.point_of_sale_rounded,
                                  size: 16,
                                  color: ThemeHelper.primaryColor(),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Cash on Hand',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: ThemeHelper.primaryColor(),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isLoading
                                  ? '...'
                                  : Helper.formatNumberWithPeso(cashOnHand),
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: ThemeHelper.primaryColor(),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Sales: ${Helper.formatNumberWithPeso(cashSales)}',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: ThemeHelper.textSecondary(),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // E-Payments Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_rounded,
                                  size: 16,
                                  color: Colors.blue.shade800,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'E-Payments',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.blue.shade900,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isLoading
                                  ? '...'
                                  : Helper.formatNumberWithPeso(epaymentSales),
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.blue.shade900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'GCash / Maya / Card',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: ThemeHelper.textSecondary(),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24),

                // Sub-metrics row
                Row(
                  children: [
                    _miniStat(
                      context: context,
                      label: 'Avg Ticket',
                      value: isLoading
                          ? '...'
                          : Helper.formatNumberWithPeso(avgTicket),
                      icon: Icons.receipt_outlined,
                    ),
                    const SizedBox(width: 8),
                    _miniStat(
                      context: context,
                      label: 'Expenses',
                      value: isLoading
                          ? '...'
                          : Helper.formatNumberWithPeso(expense),
                      icon: Icons.money_off_csred_rounded,
                      valueColor: Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    _miniStat(
                      context: context,
                      label: 'Net Balance',
                      value: isLoading
                          ? '...'
                          : Helper.formatNumberWithPeso(netSales),
                      icon: Icons.account_balance_wallet_outlined,
                      valueColor: netSales >= 0
                          ? ThemeHelper.primaryColor()
                          : Colors.red.shade700,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
