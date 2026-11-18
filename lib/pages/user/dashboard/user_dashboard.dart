import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sales_management/components/dashboard_report/low_stock_items.dart';
import 'package:sales_management/components/dashboard_report/todays_sales.dart';
import 'package:sales_management/components/dashboard_report/top_selling_today.dart';
import 'package:sales_management/components/theme_helper.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  DateTime? _lastBackPressed;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        final now = DateTime.now();

        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          _lastBackPressed = now;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          SystemNavigator.pop(); // exit app
        }
      },
      child: Container(
        color: ThemeHelper.backgroundColor(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;

            if (isWide) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Expanded(
                      child: Column(
                        children: [
                          TodaysSales(),
                          LowStockItems(),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: [
                          TopSellingToday(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              child: Column(
                children: const [
                  TodaysSales(),
                  LowStockItems(),
                  TopSellingToday(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
