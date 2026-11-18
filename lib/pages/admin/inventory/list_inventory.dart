import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/category.dart';
import 'package:sales_management/models/product.dart';
import 'package:sales_management/pages/admin/inventory/partials/inventory_card.dart';
import 'package:sales_management/pages/admin/inventory/partials/inventory_header.dart';
import 'package:sales_management/pages/admin/inventory/partials/stock_adjustment_dialog.dart';
import 'package:sales_management/services/barcode_scanner_service.dart';
import 'package:sales_management/services/user_session.dart';
import 'package:sales_management/utils/helper.dart';
import 'package:sales_management/utils/responsive.dart';

class ListInventory extends StatefulWidget {
  const ListInventory({super.key});

  @override
  State<ListInventory> createState() => _ListInventoryState();
}

class _ListInventoryState extends State<ListInventory> {
  Map<String, dynamic>? _currentUser;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedStatus = 'All'; // 'All', 'In Stock', 'Low Stock', 'Out of Stock'

  Future<List<Map<String, dynamic>>>? _productsFuture;
  Future<Map<String, dynamic>>? _summaryFuture;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadUserSession();
    _loadCategories();
    _refreshAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserSession() async {
    final user = await UserSession().loadUserSession();
    if (mounted) setState(() => _currentUser = user);
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
      _summaryFuture = Product().getInventoryValuationSummary();
    });
  }

  void _showAdjustmentDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (ctx) => StockAdjustmentDialog(
        product: product,
        currentUser: _currentUser,
        onSaved: _refreshAll,
      ),
    );
  }

  Future<void> _scanBarcodeSearch() async {
    final code = await BarcodeScannerService.scanBarcode(
      context,
      title: 'Scan Item Barcode',
      instruction: 'Scan an item barcode to check stock and inventory',
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ThemeHelper.backgroundColor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          InventoryHeader(onRefresh: _refreshAll),

          // Executive Valuation & Inventory KPI Cards
          _buildSummaryKPIs(),

          // Search Input Bar
          _buildSearchBar(),

          // Category Chips
          _buildCategoryChips(),

          const SizedBox(height: 8),

          // Inventory Products List / Grid
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
                      'Error loading inventory: ${snapshot.error}',
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
                            childAspectRatio: 2.1,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return inventoryCard(
                              inventory: product,
                              onAdjustStock: () => _showAdjustmentDialog(product),
                            );
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return inventoryCard(
                              inventory: product,
                              onAdjustStock: () => _showAdjustmentDialog(product),
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

  Widget _buildSummaryKPIs() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        final summary = snapshot.data ?? {
          'totalItems': 0,
          'totalUnits': 0.0,
          'totalCostValue': 0.0,
          'outOfStock': 0,
          'lowStock': 0,
          'inStock': 0,
        };

        final double costValue = (summary['totalCostValue'] as num?)?.toDouble() ?? 0.0;
        final double units = (summary['totalUnits'] as num?)?.toDouble() ?? 0.0;
        final int lowStock = (summary['lowStock'] as num?)?.toInt() ?? 0;
        final int outOfStock = (summary['outOfStock'] as num?)?.toInt() ?? 0;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;

              final assetCard = _buildKpiCard(
                label: 'Stock Value (Cost)',
                value: Helper.formatNumberWithPeso(costValue),
                color: ThemeHelper.primaryColor(),
                icon: Icons.account_balance_wallet_outlined,
                isActive: false,
                onTap: () {},
              );

              final unitsCard = _buildKpiCard(
                label: 'Units On Hand',
                value: Helper.formatNumber(units),
                color: Colors.blue.shade700,
                icon: Icons.inventory_outlined,
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

              final lowStockCard = _buildKpiCard(
                label: 'Low Stock Alert',
                value: '$lowStock items',
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

              final outOfStockCard = _buildKpiCard(
                label: 'Out of Stock',
                value: '$outOfStock items',
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
                        Expanded(child: assetCard),
                        const SizedBox(width: 8),
                        Expanded(child: unitsCard),
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
                    Expanded(child: assetCard),
                    const SizedBox(width: 10),
                    Expanded(child: unitsCard),
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

  Widget _buildKpiCard({
    required String label,
    required String value,
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
                    value,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: color,
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
    );
  }

  Widget _buildSearchBar() {
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
          hintText: 'Search inventory by item name or barcode...',
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
                hasFilter ? Icons.search_off : Icons.warehouse_rounded,
                size: 54,
                color: ThemeHelper.primaryColor().withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilter
                  ? 'No inventory items match your search'
                  : 'No inventory registered',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilter
                  ? 'Try searching with another keyword or resetting the filters.'
                  : 'Add products in the Catalog module to track stock levels.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: ThemeHelper.textSecondary()),
            ),
            if (hasFilter) ...[
              const SizedBox(height: 18),
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
              ),
            ],
          ],
        ),
      ),
    );
  }
}
