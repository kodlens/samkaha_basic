import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';

class Header extends StatelessWidget {
  final VoidCallback createNewProduct;
  final VoidCallback? onRefresh;
  final VoidCallback? onScanBarcode;

  const Header({
    super.key,
    required this.createNewProduct,
    this.onRefresh,
    this.onScanBarcode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: ThemeHelper.cardBackground(),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          final titleSection = Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ThemeHelper.primaryColor().withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: ThemeHelper.primaryColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product Catalog',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: ThemeHelper.textPrimary(),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage items, prices, barcodes, and inventory alerts',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: ThemeHelper.textSecondary(),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );

          final actionButtons = Row(
            mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (onScanBarcode != null) ...[
                IconButton.outlined(
                  onPressed: onScanBarcode,
                  icon: const Icon(Icons.qr_code_scanner, size: 20),
                  tooltip: 'Scan Barcode',
                  style: IconButton.styleFrom(
                    foregroundColor: ThemeHelper.primaryColor(),
                    side: BorderSide(
                      color: ThemeHelper.primaryColor().withValues(alpha: 0.3),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (onRefresh != null) ...[
                IconButton.outlined(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Refresh Catalog',
                  style: IconButton.styleFrom(
                    foregroundColor: ThemeHelper.primaryColor(),
                    side: BorderSide(
                      color: ThemeHelper.primaryColor().withValues(alpha: 0.3),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                flex: isMobile ? 1 : 0,
                child: ElevatedButton.icon(
                  onPressed: createNewProduct,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'New Product',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeHelper.primaryColor(),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleSection,
                const SizedBox(height: 14),
                actionButtons,
              ],
            );
          } else {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: titleSection),
                const SizedBox(width: 16),
                actionButtons,
              ],
            );
          }
        },
      ),
    );
  }
}
