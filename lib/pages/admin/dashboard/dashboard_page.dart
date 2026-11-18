import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sales_management/components/dashboard_report/low_stock_items.dart';
import 'package:sales_management/components/dashboard_report/recent_adjustments.dart';
import 'package:sales_management/components/dashboard_report/todays_sales.dart';
import 'package:sales_management/components/dashboard_report/top_selling_today.dart';
import 'package:sales_management/components/dashboard_report/x_report.dart';
import 'package:sales_management/components/theme_helper.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime? _lastBackPressed;
  Key _refreshKey = UniqueKey();

  void _onRefresh() {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  Widget _buildHeader(bool isWide) {
    final todayStr = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Business Overview',
                style: TextStyle(
                  fontSize: isWide ? 22 : 18,
                  fontWeight: FontWeight.bold,
                  color: ThemeHelper.textPrimary(),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.today_rounded, size: 14, color: ThemeHelper.textSecondary()),
                  const SizedBox(width: 4),
                  Text(
                    todayStr,
                    style: TextStyle(
                      fontSize: 12,
                      color: ThemeHelper.textSecondary(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            tooltip: 'Refresh Dashboard',
            onPressed: _onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            color: ThemeHelper.primaryColor(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          SystemNavigator.pop();
        }
      },
      child: Container(
        color: ThemeHelper.backgroundColor(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;

            if (isWide) {
              return RefreshIndicator(
                onRefresh: () async => _onRefresh(),
                child: SingleChildScrollView(
                  key: _refreshKey,
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(true),
                      const TodaysSales(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  LowStockItems(),
                                  TopSellingToday(),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  XReportCard(),
                                  RecentAdjustments(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Mobile view
            return RefreshIndicator(
              onRefresh: () async => _onRefresh(),
              child: SingleChildScrollView(
                key: _refreshKey,
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    TodaysSales(),
                    LowStockItems(),
                    TopSellingToday(),
                    RecentAdjustments(),
                    XReportCard(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
