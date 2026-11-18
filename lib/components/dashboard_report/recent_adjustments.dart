import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/adjustment.dart';
import 'package:sales_management/utils/helper.dart';

class RecentAdjustments extends StatefulWidget {
  const RecentAdjustments({super.key});

  @override
  State<RecentAdjustments> createState() => _RecentAdjustmentsState();
}

class _RecentAdjustmentsState extends State<RecentAdjustments> {
  late Future<List<Map<String, dynamic>>> _recentFuture;

  @override
  void initState() {
    super.initState();
    _recentFuture = Adjustment().getRecentAdjustments(limit: 5);
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'IN':
        return Colors.green.shade700;
      case 'OUT':
        return Colors.red.shade700;
      case 'SALE':
      case 'SALES':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Color _statusBg(String status) {
    switch (status.toUpperCase()) {
      case 'IN':
        return Colors.green.shade50;
      case 'OUT':
        return Colors.red.shade50;
      case 'SALE':
      case 'SALES':
        return Colors.blue.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _recentFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final items = snapshot.data ?? [];

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
                        color: ThemeHelper.darkPrimary().withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        color: ThemeHelper.darkPrimary(),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inventory Audit',
                            style: TextStyle(
                              color: ThemeHelper.textSecondary(),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Recent Adjustments',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
                          Icon(Icons.assignment_outlined, size: 36, color: Colors.grey.shade300),
                          const SizedBox(height: 6),
                          Text(
                            'No recent inventory adjustments',
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
                  ...items.map((item) {
                    final productName = (item['product_name'] ?? 'Unnamed Product').toString();
                    final status = (item['action_status'] ?? 'N/A').toString();
                    final qty = (item['quantity'] ?? 0).toString();
                    final user = [
                      item['fname'],
                      item['lname'],
                    ].where((e) => (e ?? '').toString().isNotEmpty).join(' ');
                    final tsRaw = (item['timestamp'] ?? '').toString();
                    String tsLabel = tsRaw;
                    try {
                      tsLabel = Helper.formatDateTime(DateTime.parse(tsRaw));
                    } catch (_) {}

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: _statusBg(status),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _statusColor(status),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Qty: $qty${user.isNotEmpty ? ' • By $user' : ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ThemeHelper.textSecondary(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            tsLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
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
