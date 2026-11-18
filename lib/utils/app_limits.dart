import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';

class AppLimits {
  // Feature limits for Basic Edition
  static const int maxProducts = 10;
  static const int maxCategories = 3;
  static const int maxUoms = 3;
  static const int maxAdminAccounts = 1;
  static const int maxCashierAccounts = 1;

  // Pro app package name on Google Play
  static const String proPackageName = 'com.samkaha.pos.pro';

  /// Reusable modal dialog to inform the user about Basic edition limits
  /// and invite them to download the Pro version on Google Play.
  static Future<void> showUpgradeToProDialog(
    BuildContext context, {
    required String featureName,
    String? customMessage,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.amber.shade800,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Upgrade to Pro',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customMessage ??
                    'You have reached the free Basic limit for $featureName.',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'SamKaha Pro includes:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 8),
                    _FeatureBullet(text: 'Unlimited products & inventory items'),
                    _FeatureBullet(text: 'Unlimited categories & custom units'),
                    _FeatureBullet(text: 'Full Z-Report day closure & reconciliation'),
                    _FeatureBullet(text: 'Advanced financial & sales audit reports'),
                  ],
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Maybe Later'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: ThemeHelper.primaryColor(),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                // Do nothing
              },
              icon: const Icon(Icons.shop_outlined, size: 18),
              label: const Text('Get Pro on Play Store'),
            ),
          ],
        );
      },
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  final String text;

  const _FeatureBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: Colors.green.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
