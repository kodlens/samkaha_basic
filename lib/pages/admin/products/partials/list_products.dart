import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/category.dart';
import 'package:sales_management/models/product.dart';
import 'package:sales_management/pages/admin/products/partials/add_edit_product.dart';
import 'package:sales_management/pages/admin/products/partials/header.dart';
import 'package:sales_management/pages/admin/products/partials/product_card.dart';
import 'package:sales_management/services/barcode_scanner_service.dart';
import 'package:sales_management/utils/app_limits.dart';
import 'package:sales_management/utils/responsive.dart';

class ListProducts extends StatefulWidget {
  const ListProducts({super.key});

  @override
  State<ListProducts> createState() => _ListProductsState();
}

class _ListProductsState extends State<ListProducts> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedStatus = 'All'; // 'All', 'In Stock', 'Low Stock', 'Out of Stock'

  Future<List<Map<String, dynamic>>>? _productsFuture;
  Future<Map<String, int>>? _summaryFuture;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _refreshAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await Category().getCategories();
      if (!mounted) return;
      setState(() {
        _categories = [
          'All',
          ...cats
              .map((c) => c['category']?.toString() ?? '')
              .where((c) => c.isNotEmpty && c != 'All'),
        ];
      });
    } catch (_) {}
  }

  void _refreshAll() {
    setState(() {
      _productsFuture = Product().getProducts(
        _searchQuery,
        _selectedCategory,
        _selectedStatus,
      );
      _summaryFuture = Product().getProductSummary();
    });
  }

  void _onTapEdit(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProduct(
          product: product,
          onRefresh: _refreshAll,
        ),
      ),
    );
  }

  void _createNewProduct() async {
    final allProducts = await Product().getProducts();
    if (allProducts.length >= AppLimits.maxProducts) {
      if (!mounted) return;
      AppLimits.showUpgradeToProDialog(
        context,
        featureName: 'Products',
        customMessage:
            'You have reached the limit of ${AppLimits.maxProducts} products in the Basic Edition.',
      );
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProduct(
          product: null,
          onRefresh: () {
            _loadCategories();
            _refreshAll();
          },
        ),
      ),
    );
  }

  Future<void> _scanBarcodeSearch() async {
    final code = await BarcodeScannerService.scanBarcode(
      context,
      title: 'Scan Product Barcode',
      instruction: 'Scan a product barcode to search in catalog',
    );

    if (code != null && code.isNotEmpty && mounted) {
      _searchController.text = code;
      setState(() {
        _searchQuery = code;
        _productsFuture = Product().getProducts(
          _searchQuery,
          _selectedCategory,
          _selectedStatus,
        );
      });
    }
  }

  Future<void> _onTapDelete(Map<String, dynamic> product) async {
    final productId = (product['id'] as num?)?.toInt() ?? 0;
    final productName = product['name'] ?? 'Unnamed Product';

    // Check if product has sales records
    final salesCount = await Product().countProductSales(productId);

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
            ),
            const SizedBox(width: 10),
            const Text('Delete Product'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "$productName"?',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              'This action will remove the item from the catalog.',
              style: TextStyle(fontSize: 13, color: ThemeHelper.textSecondary()),
            ),
            if (salesCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.amber.shade900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This product has $salesCount recorded sales transaction(s). Past receipts and history will be preserved.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeHelper.error(),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Product().deleteProduct(productId);
      _refreshAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "$productName"'),
          backgroundColor: ThemeHelper.primaryColor(),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ThemeHelper.backgroundColor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Title & "+ New Product" button
          Header(
            createNewProduct: _createNewProduct,
            onRefresh: _refreshAll,
            onScanBarcode: _scanBarcodeSearch,
          ),

          // Summary Metrics Banner
          _buildSummaryBar(),

          // Search and Filters Bar
          _buildSearchAndFilters(),

          // Category Filter Chips
          _buildCategoryChips(),

          const SizedBox(height: 8),

          // Product List / Grid
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading products: ${snapshot.error}',
                      style: TextStyle(color: ThemeHelper.error()),
                    ),
                  );
                }

                final products = snapshot.data ?? [];

                if (products.isEmpty) {
                  return _buildEmptyState();
                }

                final isWide = Responsive.isTablet(context) ||
                    Responsive.isDesktop(context);

                return RefreshIndicator(
                  onRefresh: () async => _refreshAll(),
                  color: ThemeHelper.primaryColor(),
                  child: isWide
                      ? GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.65,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            return productCard(
                              products[index],
                              _onTapEdit,
                              _onTapDelete,
                            );
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            return productCard(
                              products[index],
                              _onTapEdit,
                              _onTapDelete,
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    return FutureBuilder<Map<String, int>>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        final summary = snapshot.data ?? {
          'total': 0,
          'inStock': 0,
          'lowStock': 0,
          'outOfStock': 0,
        };

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;

              final totalCard = _buildMetricCard(
                label: 'Total Items',
                value: summary['total'] ?? 0,
                color: ThemeHelper.primaryColor(),
                icon: Icons.inventory_2_outlined,
                isActive: _selectedStatus == 'All',
                onTap: () {
                  setState(() {
                    _selectedStatus = 'All';
                    _productsFuture = Product().getProducts(
                      _searchQuery,
                      _selectedCategory,
                      _selectedStatus,
                    );
                  });
                },
              );

              final inStockCard = _buildMetricCard(
                label: 'In Stock',
                value: summary['inStock'] ?? 0,
                color: Colors.green.shade700,
                icon: Icons.check_circle_outline,
                isActive: _selectedStatus == 'In Stock',
                onTap: () {
                  setState(() {
                    _selectedStatus = 'In Stock';
                    _productsFuture = Product().getProducts(
                      _searchQuery,
                      _selectedCategory,
                      _selectedStatus,
                    );
                  });
                },
              );

              final lowStockCard = _buildMetricCard(
                label: 'Low Stock',
                value: summary['lowStock'] ?? 0,
                color: Colors.orange.shade800,
                icon: Icons.warning_amber_rounded,
                isActive: _selectedStatus == 'Low Stock',
                onTap: () {
                  setState(() {
                    _selectedStatus = 'Low Stock';
                    _productsFuture = Product().getProducts(
                      _searchQuery,
                      _selectedCategory,
                      _selectedStatus,
                    );
                  });
                },
              );

              final outOfStockCard = _buildMetricCard(
                label: 'Out of Stock',
                value: summary['outOfStock'] ?? 0,
                color: Colors.red.shade700,
                icon: Icons.cancel_outlined,
                isActive: _selectedStatus == 'Out of Stock',
                onTap: () {
                  setState(() {
                    _selectedStatus = 'Out of Stock';
                    _productsFuture = Product().getProducts(
                      _searchQuery,
                      _selectedCategory,
                      _selectedStatus,
                    );
                  });
                },
              );

              if (isNarrow) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: totalCard),
                        const SizedBox(width: 8),
                        Expanded(child: inStockCard),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: lowStockCard),
                        const SizedBox(width: 8),
                        Expanded(child: outOfStockCard),
                      ],
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(child: totalCard),
                    const SizedBox(width: 10),
                    Expanded(child: inStockCard),
                    const SizedBox(width: 10),
                    Expanded(child: lowStockCard),
                    const SizedBox(width: 10),
                    Expanded(child: outOfStockCard),
                  ],
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String label,
    required int value,
    required Color color,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.12)
              : ThemeHelper.cardBackground(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : Colors.grey.withValues(alpha: 0.2),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ThemeHelper.textSecondary(),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: color,
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

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val.trim();
            _productsFuture = Product().getProducts(
              _searchQuery,
              _selectedCategory,
              _selectedStatus,
            );
          });
        },
        decoration: InputDecoration(
          hintText: 'Search products by name or barcode...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _productsFuture = Product().getProducts(
                        _searchQuery,
                        _selectedCategory,
                        _selectedStatus,
                      );
                    });
                  },
                ),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner, size: 20),
                tooltip: 'Scan barcode with camera',
                onPressed: _scanBarcodeSearch,
              ),
              const SizedBox(width: 4),
            ],
          ),
          filled: true,
          fillColor: ThemeHelper.cardBackground(),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: ThemeHelper.primaryColor(), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    if (_categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat == 'All' ? 'All Categories' : cat),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = cat;
                    _productsFuture = Product().getProducts(
                      _searchQuery,
                      _selectedCategory,
                      _selectedStatus,
                    );
                  });
                }
              },
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : ThemeHelper.textPrimary(),
              ),
              selectedColor: ThemeHelper.primaryColor(),
              backgroundColor: ThemeHelper.cardBackground(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected
                      ? ThemeHelper.primaryColor()
                      : Colors.grey.withValues(alpha: 0.25),
                ),
              ),
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool hasFilter = _searchQuery.isNotEmpty ||
        _selectedCategory != 'All' ||
        _selectedStatus != 'All';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeHelper.primaryColor().withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilter ? Icons.search_off : Icons.inventory_2_outlined,
                size: 54,
                color: ThemeHelper.primaryColor().withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilter ? 'No products match your filters' : 'No products in catalog yet',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilter
                  ? 'Try searching with another keyword or resetting your filters.'
                  : 'Get started by adding your first product to the catalog.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: ThemeHelper.textSecondary()),
            ),
            const SizedBox(height: 18),
            if (hasFilter)
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedCategory = 'All';
                    _selectedStatus = 'All';
                    _productsFuture = Product().getProducts();
                  });
                },
                icon: const Icon(Icons.filter_alt_off, size: 16),
                label: const Text('Reset All Filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ThemeHelper.primaryColor(),
                  side: BorderSide(color: ThemeHelper.primaryColor()),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _createNewProduct,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeHelper.primaryColor(),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
