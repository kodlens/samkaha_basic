import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/product.dart';

class LowStockItems extends StatefulWidget {
  const LowStockItems({super.key});

  @override
  State<LowStockItems> createState() => _LowStockItemsState();
}

class _LowStockItemsState extends State<LowStockItems> {
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _dataFuture = _fetchLowStockData();
  }

  Future<Map<String, dynamic>> _fetchLowStockData() async {
    final count = await Product().getLowStockCount();
    final items = await Product().getLowStockItemsList(limit: 4);
    return {
      'count': count,
      'items': items,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final data = snapshot.data ?? {};
          final count = (data['count'] as num?)?.toInt() ?? 0;
          final items = (data['items'] as List<Map<String, dynamic>>?) ?? [];

          final bool hasLowStock = count > 0;

          return Container(
            decoration: BoxDecoration(
              color: ThemeHelper.cardBackground(),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: hasLowStock
                    ? Colors.orange.shade300
                    : ThemeHelper.lightPrimary().withValues(alpha: 0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (hasLowStock ? Colors.orange : ThemeHelper.primaryColor())
                      .withValues(alpha: 0.04),
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
                        color: hasLowStock
                            ? Colors.orange.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        hasLowStock
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline_rounded,
                        color: hasLowStock ? Colors.orange.shade800 : Colors.green.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Low Stock Attention',
                            style: TextStyle(
                              color: ThemeHelper.textSecondary(),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasLowStock ? '$count Items Under Threshold' : 'Inventory Healthy',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: hasLowStock ? Colors.orange.shade900 : Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasLowStock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$count Alert${count > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                  ],
                ),

                if (isLoading) ...[
                  const SizedBox(height: 14),
                  const LinearProgressIndicator(),
                ] else if (!hasLowStock) ...[
                  const SizedBox(height: 10),
                  Text(
                    'All products are well-stocked above their minimum limits.',
                    style: TextStyle(
                      fontSize: 12,
                      color: ThemeHelper.textSecondary(),
                    ),
                  ),
                ] else ...[
                  const Divider(height: 20),
                  ...items.map((item) {
                    final name = item['name']?.toString() ?? '';
                    final stock = (item['stock'] as num?)?.toDouble() ?? 0.0;
                    final minStock = (item['low_stock_level'] as num?)?.toDouble() ?? 5.0;
                    final unit = item['unit']?.toString() ?? 'pcs';
                    final bool isZero = stock <= 0;

                    // Progress percentage between 0 and 1
                    final progress = minStock > 0 ? (stock / minStock).clamp(0.0, 1.0) : 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
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
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isZero ? Colors.red.shade50 : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isZero ? 'Out of stock' : '${stock.toInt()} $unit left (min $minStock)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isZero ? Colors.red.shade700 : Colors.orange.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation(
                                isZero ? Colors.red : Colors.orange.shade600,
                              ),
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
