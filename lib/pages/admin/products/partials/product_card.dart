import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/utils/helper.dart';

Widget productCard(
  Map<String, dynamic> product,
  void Function(Map<String, dynamic> product) onTapEdit,
  void Function(Map<String, dynamic> product) onTapDelete,
) {
  final num stock = (product['stock'] as num?) ?? 0;
  final num lowStockLevel = (product['low_stock_level'] as num?) ?? 0;
  final num sellingPrice = (product['selling_price'] as num?) ?? 0;
  final num costPrice = (product['cost_price'] as num?) ?? 0;
  final num margin = sellingPrice - costPrice;
  final double marginPercent = costPrice > 0 ? ((margin / costPrice) * 100) : 0;

  final bool isOutOfStock = stock <= 0;
  final bool isLowStock = !isOutOfStock && stock <= lowStockLevel;

  Color stockBgColor;
  Color stockTextColor;
  IconData stockIcon;
  String stockLabel;

  if (isOutOfStock) {
    stockBgColor = Colors.red.withValues(alpha: 0.12);
    stockTextColor = Colors.red.shade700;
    stockIcon = Icons.cancel_outlined;
    stockLabel = 'Out of Stock (0)';
  } else if (isLowStock) {
    stockBgColor = Colors.orange.withValues(alpha: 0.15);
    stockTextColor = Colors.orange.shade800;
    stockIcon = Icons.warning_amber_rounded;
    stockLabel = 'Low Stock ($stock left)';
  } else {
    stockBgColor = ThemeHelper.primaryColor().withValues(alpha: 0.12);
    stockTextColor = ThemeHelper.primaryColor();
    stockIcon = Icons.check_circle_outline;
    stockLabel = '$stock ${product['unit'] ?? 'units'} in stock';
  }

  final imagePath = product['image_path']?.toString() ?? '';
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
      onTap: () => onTapEdit(product),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image / Placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 82,
                height: 82,
                color: ThemeHelper.primaryColor().withValues(alpha: 0.08),
                child: hasImage
                    ? Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallbackImage(product),
                      )
                    : _buildFallbackImage(product),
              ),
            ),
            const SizedBox(width: 14),

            // Product Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: Title & Barcode
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product['name'] ?? 'Unnamed Product',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Category, Unit, & Barcode Badges
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (product['category'] != null &&
                          product['category'].toString().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product['category'].toString(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ThemeHelper.textSecondary(),
                            ),
                          ),
                        ),
                      if (product['unit'] != null &&
                          product['unit'].toString().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product['unit'].toString().toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      if (product['barcode'] != null &&
                          product['barcode'].toString().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.barcode_reader,
                                  size: 11, color: Colors.purple.shade700),
                              const SizedBox(width: 3),
                              Text(
                                product['barcode'].toString(),
                                style: TextStyle(
                                  fontSize: 11,
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
                  const SizedBox(height: 8),

                  // Pricing & Margin Row
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      Text(
                        Helper.formatNumberWithPeso(sellingPrice),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: ThemeHelper.primaryColor(),
                        ),
                      ),
                      Text(
                        'Cost: ${Helper.formatNumberWithPeso(costPrice)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: ThemeHelper.textSecondary(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (margin > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '+${marginPercent.toStringAsFixed(0)}% profit',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Stock Status Indicator Pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: stockBgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(stockIcon, size: 13, color: stockTextColor),
                        const SizedBox(width: 5),
                        Text(
                          stockLabel,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: stockTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Actions (Edit & Delete)
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: ThemeHelper.primaryColor(),
                  tooltip: 'Edit Product',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onTapEdit(product),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: ThemeHelper.error(),
                  tooltip: 'Delete Product',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onTapDelete(product),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildFallbackImage(Map<String, dynamic> product) {
  final name = (product['name']?.toString() ?? 'P').trim();
  final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';

  return Center(
    child: Text(
      initial,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: ThemeHelper.primaryColor(),
      ),
    ),
  );
}
