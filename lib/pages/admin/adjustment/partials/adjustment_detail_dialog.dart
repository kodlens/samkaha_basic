import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/utils/helper.dart';

class AdjustmentDetailDialog extends StatelessWidget {
  final Map<String, dynamic> log;

  const AdjustmentDetailDialog({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final String action = (log['action_status'] ?? 'IN').toString().toUpperCase();
    final num qty = (log['quantity'] as num?) ?? 0;
    final num currentStock = (log['current_stock'] as num?) ?? 0;
    final num liveStock = (log['current_live_stock'] ?? log['stock'] as num?) ?? 0;
    final String unit = (log['product_unit'] ?? 'PCS').toString().toUpperCase();
    final String reason = (log['reason']?.toString().isNotEmpty ?? false)
        ? log['reason'].toString()
        : 'No remarks provided';

    Color actionColor;
    IconData actionIcon;
    String actionTitle;
    String qtyPrefix;

    if (action == 'IN') {
      actionColor = Colors.green;
      actionIcon = Icons.add_circle_outline;
      actionTitle = 'Stock In / Receiving';
      qtyPrefix = '+';
    } else if (action == 'OUT' || action == 'SALES') {
      actionColor = Colors.orange.shade800;
      actionIcon = Icons.remove_circle_outline;
      actionTitle = 'Stock Out / Deduction';
      qtyPrefix = '-';
    } else {
      actionColor = Colors.blue.shade700;
      actionIcon = Icons.fact_check_outlined;
      actionTitle = 'Physical Count Audit';
      qtyPrefix = '= ';
    }

    DateTime? timestamp;
    try {
      if (log['timestamp'] != null) {
        timestamp = DateTime.parse(log['timestamp'].toString());
      }
    } catch (_) {}

    final staffName =
        '${log['fname'] ?? ''} ${log['lname'] ?? ''}'.trim().isEmpty
            ? (log['username'] ?? 'Staff')
            : '${log['fname'] ?? ''} ${log['lname'] ?? ''}'.trim();

    final imagePath = log['product_image']?.toString() ?? '';
    final hasImage = imagePath.isNotEmpty && File(imagePath).existsSync();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: ThemeHelper.cardBackground(),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Action Badge + Log ID + Close
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: actionColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: actionColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(actionIcon, size: 15, color: actionColor),
                        const SizedBox(width: 5),
                        Text(
                          actionTitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: actionColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'LOG #${log['id']}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: ThemeHelper.textSecondary(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Product Info Block
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 50,
                      height: 50,
                      color:
                          ThemeHelper.primaryColor().withValues(alpha: 0.08),
                      child: hasImage
                          ? Image.file(File(imagePath), fit: BoxFit.cover)
                          : Center(
                              child: Text(
                                (log['product_name']?.toString() ?? 'P')
                                    .trim()
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: ThemeHelper.primaryColor(),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log['product_name'] ?? 'Unnamed Product',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 6,
                          children: [
                            if (log['product_category'] != null)
                              Text(
                                log['product_category'].toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ThemeHelper.textSecondary(),
                                ),
                              ),
                            Text(
                              '• Live On-Hand: $liveStock $unit',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ThemeHelper.primaryColor(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // KPI Adjustment Metrics Box
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: actionColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          'QUANTITY',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: ThemeHelper.textSecondary(),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$qtyPrefix$qty $unit',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: actionColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: actionColor.withValues(alpha: 0.2),
                    ),
                    Column(
                      children: [
                        Text(
                          'POST-ADJUST STOCK',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: ThemeHelper.textSecondary(),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$currentStock $unit',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: ThemeHelper.textPrimary(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Reason & Details
              _buildDetailItem(
                label: 'REASON / REMARKS',
                icon: Icons.notes_outlined,
                content: Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Transacted By
              _buildDetailItem(
                label: 'TRANSACTED BY',
                icon: Icons.person_outline,
                content: Row(
                  children: [
                    Text(
                      staffName,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (log['role'] != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: ThemeHelper.primaryColor().withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log['role'].toString().toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: ThemeHelper.primaryColor(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Date & Time
              if (timestamp != null)
                _buildDetailItem(
                  label: 'DATE & TIME',
                  icon: Icons.access_time_outlined,
                  content: Text(
                    Helper.formatDateTime(timestamp),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 22),

              // Close Action
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeHelper.primaryColor(),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Close Details',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required String label,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: ThemeHelper.textSecondary()),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: ThemeHelper.textSecondary(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          content,
        ],
      ),
    );
  }
}
