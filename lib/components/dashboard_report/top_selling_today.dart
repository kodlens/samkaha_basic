import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/transaction_details.dart';
import 'package:sales_management/utils/helper.dart';

class TopSellingToday extends StatefulWidget {
  const TopSellingToday({super.key});

  @override
  State<TopSellingToday> createState() => _TopSellingTodayState();
}

class _TopSellingTodayState extends State<TopSellingToday> {
  late Future<List<Map<String, dynamic>>> _topSellingFuture;

  @override
  void initState() {
    super.initState();
    _topSellingFuture = TransactionDetails().getTopSellingToday(limit: 5);
  }

  Color _rankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFEAB308); // Gold
      case 1:
        return const Color(0xFF94A3B8); // Silver
      case 2:
        return const Color(0xFFD97706); // Bronze
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _topSellingFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final items = snapshot.data ?? [];

          final double maxQty = items.isNotEmpty
              ? ((items.first['total_qty'] as num?)?.toDouble() ?? 1.0)
              : 1.0;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFD97706),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Top Movers",
                            style: TextStyle(
                              color: ThemeHelper.textSecondary(),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "Best Selling Products",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ThemeHelper.backgroundColor(),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        'Top 5',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: ThemeHelper.primaryColor(),
                        ),
                      ),
                    ),
                  ],
                ),

                if (isLoading) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                ] else if (items.isEmpty) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          Icon(Icons.query_stats_rounded, size: 36, color: Colors.grey.shade300),
                          const SizedBox(height: 6),
                          Text(
                            'No sales recorded yet today',
                            style: TextStyle(
                              color: ThemeHelper.textSecondary(),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  const Divider(height: 22),
                  ...items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final name = (item['product_name'] ?? 'Unnamed Product').toString();
                    final qty = (item['total_qty'] as num?)?.toDouble() ?? 0.0;
                    final sales = (item['total_sales'] as num?)?.toDouble() ?? 0.0;
                    final progress = maxQty > 0 ? (qty / maxQty).clamp(0.0, 1.0) : 0.0;
                    final rankColor = _rankColor(index);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Rank Badge
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: rankColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: rankColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${qty.toInt()} sold',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                Helper.formatNumberWithPeso(sales),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: ThemeHelper.primaryColor(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.shade100,
                              valueColor: AlwaysStoppedAnimation(ThemeHelper.primaryColor()),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
