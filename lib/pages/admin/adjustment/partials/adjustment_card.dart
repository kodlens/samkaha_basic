import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/utils/helper.dart';

Widget adjustmentCard({
  required Map<String, dynamic> log,
  required VoidCallback onTap,
}) {
  final String action = (log['action_status'] ?? 'IN').toString().toUpperCase();
  final num qty = (log['quantity'] as num?) ?? 0;
  final num currentStock = (log['current_stock'] as num?) ?? 0;
  final String unit = (log['product_unit'] ?? 'PCS').toString().toUpperCase();
  final String reason = (log['reason']?.toString().isNotEmpty ?? false)
      ? log['reason'].toString()
      : 'Stock adjustment';

  Color actionColor;
  IconData actionIcon;
  String qtyLabel;

  if (action == 'IN') {
    actionColor = Colors.green;
    actionIcon = Icons.arrow_downward_rounded;
    qtyLabel = '+$qty $unit';
  } else if (action == 'OUT' || action == 'SALES') {
    actionColor = Colors.orange.shade800;
    actionIcon = Icons.arrow_upward_rounded;
    qtyLabel = '-$qty $unit';
  } else {
    actionColor = Colors.blue.shade700;
    actionIcon = Icons.sync_alt_rounded;
    qtyLabel = '= $qty $unit';
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

  return Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: Colors.grey.withValues(alpha: 0.2),
        width: 1,
      ),
    ),
    color: ThemeHelper.cardBackground(),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action Icon Avatar or Product Photo
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 48,
                height: 48,
                color: actionColor.withValues(alpha: 0.12),
                child: hasImage
                    ? Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(actionIcon, color: actionColor, size: 24),
                      )
                    : Icon(actionIcon, color: actionColor, size: 24),
              ),
            ),
            const SizedBox(width: 12),

            // Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name + Quantity Badge Row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          log['product_name'] ?? 'Unnamed Product',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: actionColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          qtyLabel,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: actionColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Reason & Category Chips
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          reason,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: ThemeHelper.textSecondary(),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Metadata Row: Staff, Timestamp, and Post-Adjustment Stock
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      // Staff Chip
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_outline,
                              size: 13, color: ThemeHelper.textSecondary()),
                          const SizedBox(width: 3),
                          Text(
                            staffName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ThemeHelper.textSecondary(),
                            ),
                          ),
                        ],
                      ),

                      // Timestamp
                      if (timestamp != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time,
                                size: 12, color: ThemeHelper.textSecondary()),
                            const SizedBox(width: 3),
                            Text(
                              Helper.formatDateTime(timestamp),
                              style: TextStyle(
                                fontSize: 11,
                                color: ThemeHelper.textSecondary(),
                              ),
                            ),
                          ],
                        ),

                      // Resulting Stock
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Stock: $currentStock $unit',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: ThemeHelper.textPrimary(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),

            // Subtle arrow indicator
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
