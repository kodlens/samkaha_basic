import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/category.dart';
import 'package:sales_management/pages/admin/category/partials/add_edit_category.dart';
import 'package:sales_management/utils/app_limits.dart';

class CategoryHeader extends StatelessWidget {
  const CategoryHeader({super.key, required this.refreshData});

  final Function refreshData;

  void _handleCreate(BuildContext context) async {
    final list = await Category().getCategories();
    final realCategories = list
        .where((c) => (c['category'] ?? '').toString().isNotEmpty && (c['category'] ?? '') != 'All')
        .toList();
    if (realCategories.length >= AppLimits.maxCategories) {
      if (!context.mounted) return;
      AppLimits.showUpgradeToProDialog(
        context,
        featureName: 'Categories',
        customMessage:
            'You have reached the maximum of ${AppLimits.maxCategories} categories in the Basic Edition.',
      );
      return;
    }

    if (!context.mounted) return;
    showAddEditCategory(context, onSubmit, {'id': 0, 'category': ''});
  }

  Future<void> onSubmit(Map<String, dynamic> category) async {
    await Category().insertCategory({
      'id': 0,
      'category': category['category'],
    });
    refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: ThemeHelper.cardBackground(),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          final titleSection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category Management',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 22,
                  fontWeight: FontWeight.bold,
                  color: ThemeHelper.textPrimary(),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Organize products into groups for faster POS & reports',
                style: TextStyle(
                  fontSize: 12,
                  color: ThemeHelper.textSecondary(),
                ),
              ),
            ],
          );

          final createButton = ElevatedButton.icon(
            onPressed: () => _handleCreate(context),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'New Category',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeHelper.primaryColor(),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
            ),
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleSection,
                const SizedBox(height: 12),
                createButton,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: titleSection),
              const SizedBox(width: 16),
              createButton,
            ],
          );
        },
      ),
    );
  }
}
