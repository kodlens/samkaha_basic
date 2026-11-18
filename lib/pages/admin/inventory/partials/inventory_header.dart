import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';

class InventoryHeader extends StatelessWidget {
  final VoidCallback onRefresh;

  const InventoryHeader({
    super.key,
    required this.onRefresh,
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
                  Icons.warehouse_rounded,
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
                      'Inventory & Stock Levels',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: ThemeHelper.textPrimary(),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Real-time physical stock counts, asset valuations, and restock actions',
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

          final refreshBtn = IconButton.outlined(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh Inventory',
            style: IconButton.styleFrom(
              foregroundColor: ThemeHelper.primaryColor(),
              side: BorderSide(
                color: ThemeHelper.primaryColor().withValues(alpha: 0.3),
              ),
            ),
          );

          if (isMobile) {
            return Row(
              children: [
                Expanded(child: titleSection),
                const SizedBox(width: 8),
                refreshBtn,
              ],
            );
          } else {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: titleSection),
                const SizedBox(width: 16),
                refreshBtn,
              ],
            );
          }
        },
      ),
    );
  }
}
