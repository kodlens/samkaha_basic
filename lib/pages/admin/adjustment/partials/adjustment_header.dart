import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';

class AdjustmentHeader extends StatelessWidget {
  final VoidCallback onRefresh;

  const AdjustmentHeader({
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ThemeHelper.primaryColor().withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.history_rounded,
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
                        'Stock Adjustment Logs',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: ThemeHelper.textPrimary(),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Audit trail of restocks, write-offs, and count reconciliations',
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
            ),
          ),
          const SizedBox(width: 12),
          IconButton.outlined(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh Logs',
            style: IconButton.styleFrom(
              foregroundColor: ThemeHelper.primaryColor(),
              side: BorderSide(
                color: ThemeHelper.primaryColor().withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
