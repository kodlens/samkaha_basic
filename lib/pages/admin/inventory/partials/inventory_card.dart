import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/utils/helper.dart';

Widget inventoryCard({
  required Map<String, dynamic> inventory,
  required VoidCallback onAdjustStock,
}) {
  final num stock = (inventory['stock'] as num?) ?? 0;
  final num lowStockLevel = (inventory['low_stock_level'] as num?) ?? 0;
  final num costPrice = (inventory['cost_price'] as num?) ?? 0;
  final num totalValuation = stock * costPrice;
  final String unit = (inventory['unit'] ?? 'PCS').toString().toUpperCase();

  final bool isOutOfStock = stock <= 0;
  final bool isLowStock = !isOutOfStock && stock <= lowStockLevel;

  Color statusColor;
  Color statusBgColor;
  IconData statusIcon;
  String statusLabel;

  if (isOutOfStock) {
    statusColor = Colors.red.shade700;
    statusBgColor = Colors.red.withValues(alpha: 0.12);
    statusIcon = Icons.cancel_outlined;
    statusLabel = 'Out of Stock';
  } else if (isLowStock) {
    statusColor = Colors.orange.shade800;
    statusBgColor = Colors.orange.withValues(alpha: 0.15);
    statusIcon = Icons.warning_amber_rounded;
    statusLabel = 'Low Stock';
  } else {
    statusColor = ThemeHelper.primaryColor();
    statusBgColor = ThemeHelper.primaryColor().withValues(alpha: 0.12);
    statusIcon = Icons.check_circle_outline;
    statusLabel = 'In Stock';
  }

  final imagePath = inventory['image_path']?.toString() ?? '';
  final hasImage = imagePath.isNotEmpty && File(imagePath).existsSync();

  return Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: isOutOfStock
            ? Colors.red.withValues(alpha: 0.3)
            : isLowStock
                ? Colors.orange.withValues(alpha: 0.35)
                : Colors.grey.withValues(alpha: 0.2),
        width: 1,
      ),
    ),
    color: ThemeHelper.cardBackground(),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onAdjustStock,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Image + Name + Category + Badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 52,
                    height: 52,
                    color: ThemeHelper.primaryColor().withValues(alpha: 0.08),
                    child: hasImage
                        ? Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildFallbackImage(inventory),
                          )
                        : _buildFallbackImage(inventory),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inventory['name'] ?? 'Unnamed Product',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // Category and Barcode badges
                      Wrap(
                        spacing: 5,
                        runSpacing: 3,
                        children: [
                          if (inventory['category'] != null &&
                              inventory['category'].toString().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                inventory['category'].toString(),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: ThemeHelper.textSecondary(),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (inventory['barcode'] != null &&
                              inventory['barcode'].toString().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.barcode_reader,
                                      size: 10,
                                      color: Colors.purple.shade700),
                                  const SizedBox(width: 2),
                                  Text(
                                    inventory['barcode'].toString(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w600,
                                      color: Colors.purple.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 3),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Bottom Metric Row: Bounded and Overflow-Safe
            Row(
              children: [
                // Stock on Hand Metric
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ON HAND',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: ThemeHelper.textSecondary(),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              '$stock',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: isOutOfStock
                                    ? Colors.red.shade700
                                    : isLowStock
                                        ? Colors.orange.shade800
                                        : ThemeHelper.textPrimary(),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            unit,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: ThemeHelper.textSecondary(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Asset Valuation Metric
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'VALUATION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: ThemeHelper.textSecondary(),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        Helper.formatNumberWithPeso(totalValuation),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: ThemeHelper.primaryColor(),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Cost: ${Helper.formatNumberWithPeso(costPrice)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: ThemeHelper.textSecondary(),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Adjust Stock Button
                ElevatedButton.icon(
                  onPressed: onAdjustStock,
                  icon: const Icon(Icons.tune_rounded, size: 14),
                  label: const Text(
                    'Adjust',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeHelper.primaryColor(),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildFallbackImage(Map<String, dynamic> inventory) {
  final name = (inventory['name']?.toString() ?? 'P').trim();
  final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';

  return Center(
    child: Text(
      initial,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: ThemeHelper.primaryColor(),
      ),
    ),
  );
}
