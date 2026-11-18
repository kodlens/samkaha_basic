import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/category.dart';
import 'package:sales_management/models/product.dart';
import 'package:sales_management/pages/user/pos/checkout.dart';
import '../../../utils/helper.dart';

class PointOfSaleTablet extends StatefulWidget {
  const PointOfSaleTablet({super.key});

  @override
  State<PointOfSaleTablet> createState() => _PointOfSaleTabletState();
}

class _PointOfSaleTabletState extends State<PointOfSaleTablet> {
  Future<List<Map<String, dynamic>>>? _future;
  String? selectedCategory = 'All';
  List<String> categoryDropdown = ['All'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Selected products with quantity
  final List<Map<String, dynamic>> cart = [];

  @override
  void initState() {
    super.initState();
    loadCategories();
    _future = Product().getProducts(null);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void loadCategories() async {
    final cat = await Category().getCategories();
    if (mounted) {
      setState(() {
        categoryDropdown =
            ['All'] + cat.map((c) => c['category'].toString()).toList();
      });
    }
  }

  StateSetter? _modalSetState;

  void _updateCart(VoidCallback fn) {
    setState(() {
      fn();
    });
    _modalSetState?.call(() {});
  }

  void addToCart(Map<String, dynamic> product) {
    final index = cart.indexWhere((item) => item['id'] == product['id']);
    final stock = (product['stock'] as num?)?.toDouble();

    if (index >= 0) {
      if (stock != null && stock > 0 && (cart[index]['quantity'] as num) >= stock) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot exceed available stock (${stock.toInt()}) for ${product['name']}'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      _updateCart(() {
        cart[index]['quantity'] = (cart[index]['quantity'] as num) + 1;
      });
    } else {
      if (stock == null || stock > 0) {
        _updateCart(() {
          cart.add({...product, 'quantity': 1});
        });
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product['name']} is currently out of stock'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void removeFromCart(int index) {
    if (index < 0 || index >= cart.length) return;
    _updateCart(() {
      cart.removeAt(index);
    });
  }

  void incrementQuantity(int index) {
    if (index < 0 || index >= cart.length) return;
    final item = cart[index];
    final stock = (item['stock'] as num?)?.toDouble();
    final currentQty = (item['quantity'] as num);

    if (stock != null && stock > 0 && currentQty >= stock) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reached max available stock (${stock.toInt()}) for ${item['name']}'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _updateCart(() {
      cart[index]['quantity'] = currentQty + 1;
    });
  }

  void decrementQuantity(int index) {
    if (index < 0 || index >= cart.length) return;
    _updateCart(() {
      final currentQty = (cart[index]['quantity'] as num);
      if (currentQty > 1) {
        cart[index]['quantity'] = currentQty - 1;
      } else {
        cart.removeAt(index);
      }
    });
  }

  void _clearCart() {
    _updateCart(() {
      cart.clear();
      _future = Product().getProducts(null);
    });
  }

  double get total => cart.fold(
        0,
        (sum, item) => sum + ((item['selling_price'] as num) * (item['quantity'] as num)),
      );

  int get totalItemCount => cart.fold(
        0,
        (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0),
      );

  void _navigateToCheckout({bool fromBottomSheet = false}) {
    if (cart.isEmpty) return;
    if (fromBottomSheet && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Checkout(
          cart: cart,
          totalAmount: total,
          onCartCleared: _clearCart,
        ),
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val.trim().toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search products by name or code...',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categoryDropdown.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categoryDropdown[index];
          final isSelected = (selectedCategory ?? 'All') == cat;

          return FilterChip(
            selected: isSelected,
            label: Text(cat),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : ThemeHelper.textPrimary(),
            ),
            backgroundColor: Colors.white,
            selectedColor: ThemeHelper.primaryColor(),
            showCheckmark: false,
            side: BorderSide(
              color: isSelected ? ThemeHelper.primaryColor() : Colors.grey.shade300,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            onSelected: (val) {
              setState(() {
                selectedCategory = cat;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(BoxConstraints constraints) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No products available'));
        }

        List<Map<String, dynamic>> filtered = snapshot.data!;

        // Filter by category
        if (selectedCategory != null && selectedCategory != 'All') {
          filtered = filtered
              .where((item) => item['category'] == selectedCategory)
              .toList();
        }

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          filtered = filtered.where((item) {
            final name = (item['name']?.toString() ?? '').toLowerCase();
            final code = (item['product_code']?.toString() ?? '').toLowerCase();
            final barcode = (item['barcode']?.toString() ?? '').toLowerCase();
            return name.contains(_searchQuery) ||
                code.contains(_searchQuery) ||
                barcode.contains(_searchQuery);
          }).toList();
        }

        if (filtered.isEmpty) {
          return const Center(child: Text('No matching products found'));
        }

        // Dynamic column calculation based on available width
        final availableWidth = constraints.maxWidth;
        final int columns = availableWidth < 380
            ? 2
            : availableWidth < 600
                ? 2
                : availableWidth < 900
                    ? 3
                    : availableWidth < 1200
                        ? 4
                        : 5;

        return GridView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.72,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final product = filtered[index];
            final stock = (product['stock'] as num?)?.toDouble() ?? 0;
            final lowStock = (product['low_stock_level'] as num?)?.toDouble() ?? 5;
            final bool outOfStock = stock <= 0;

            final imageFile = (product['image_path'] != null &&
                    product['image_path'].toString().isNotEmpty)
                ? File(product['image_path'])
                : null;

            return Card(
              elevation: 2,
              shadowColor: ThemeHelper.primaryColor().withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: outOfStock ? Colors.red.shade200 : Colors.grey.shade200,
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: outOfStock ? null : () => addToCart(product),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Image Container
                        Expanded(
                          flex: 3,
                          child: Container(
                            color: Colors.grey.shade100,
                            child: imageFile != null && imageFile.existsSync()
                                ? Image.file(imageFile, fit: BoxFit.cover)
                                : Icon(
                                    Icons.inventory_2_outlined,
                                    size: 38,
                                    color: Colors.grey.shade400,
                                  ),
                          ),
                        ),

                        // Product Details
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  product['name']?.toString() ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: outOfStock
                                            ? Colors.red.shade50
                                            : stock <= lowStock
                                                ? Colors.orange.shade50
                                                : Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        outOfStock
                                            ? '0 left'
                                            : '${stock.toInt()} left',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: outOfStock
                                              ? Colors.red.shade700
                                              : stock <= lowStock
                                                  ? Colors.orange.shade800
                                                  : Colors.green.shade700,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      Helper.formatNumberWithPeso(product['selling_price']),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        color: ThemeHelper.primaryColor(),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Out of stock overlay
                    if (outOfStock)
                      Container(
                        color: Colors.white.withValues(alpha: 0.75),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Out of Stock',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= CART COMPONENT =================

  Widget _buildCartPanel({bool isBottomSheet = false}) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cart Header
          Row(
            children: [
              Icon(Icons.shopping_bag_outlined, color: ThemeHelper.primaryColor()),
              const SizedBox(width: 8),
              Text(
                'Cart ($totalItemCount)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (cart.isNotEmpty)
                TextButton.icon(
                  onPressed: _clearCart,
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  label: const Text(
                    'Clear',
                    style: TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
            ],
          ),
          const Divider(height: 16),

          // Items List
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.remove_shopping_cart_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your cart is empty',
                          style: TextStyle(color: ThemeHelper.textSecondary()),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: cart.length,
                    separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      final qty = item['quantity'] as num;
                      final price = item['selling_price'] as num;
                      final itemTotal = qty * price;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${Helper.formatNumberWithPeso(price)} • Sub: ${Helper.formatNumberWithPeso(itemTotal)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ThemeHelper.textSecondary(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: ThemeHelper.backgroundColor(),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => decrementQuantity(index),
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(9),
                                    ),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      alignment: Alignment.center,
                                      child: Icon(
                                        qty > 1
                                            ? Icons.remove
                                            : Icons.delete_outline,
                                        size: 16,
                                        color: qty > 1
                                            ? ThemeHelper.textPrimary()
                                            : Colors.red.shade600,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    constraints: const BoxConstraints(minWidth: 28),
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      '$qty',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => incrementQuantity(index),
                                    borderRadius: const BorderRadius.horizontal(
                                      right: Radius.circular(9),
                                    ),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.add,
                                        size: 16,
                                        color: ThemeHelper.primaryColor(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          const Divider(height: 16),

          // Total and Checkout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                Helper.formatNumberWithPeso(total),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: ThemeHelper.primaryColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: cart.isEmpty
                  ? null
                  : () => _navigateToCheckout(fromBottomSheet: isBottomSheet),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeHelper.primaryColor(),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.payment),
              label: const Text(
                'Proceed to Checkout',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (isBottomSheet)
            SizedBox(
              height: MediaQuery.of(context).padding.bottom > 0 ? 10 : 16,
            ),
        ],
      ),
    );
  }

  void _showMobileCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            _modalSetState = setModalState;
            return FractionallySizedBox(
              heightFactor: 0.75,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Expanded(
                        child: _buildCartPanel(isBottomSheet: true),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _modalSetState = null;
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 768;

        if (isWide) {
          // Tablet & Desktop: Side-by-side Catalog + Live Cart Panel
          return Row(
            children: [
              // Catalog (Left)
              Expanded(
                flex: 3,
                child: Container(
                  color: ThemeHelper.backgroundColor(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 10),
                      _buildCategorySelector(),
                      const SizedBox(height: 10),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, innerConstraints) =>
                              _buildProductGrid(innerConstraints),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Cart Panel (Right)
              SizedBox(
                width: 360,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: _buildCartPanel(),
                ),
              ),
            ],
          );
        }

        // Mobile Phone: Full width catalog with floating bottom cart bar
        return Container(
          color: ThemeHelper.backgroundColor(),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 10),
                    _buildCategorySelector(),
                    const SizedBox(height: 8),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, innerConstraints) =>
                            _buildProductGrid(innerConstraints),
                      ),
                    ),
                  ],
                ),
              ),

              // Mobile Floating Bottom Cart Bar
              if (cart.isNotEmpty)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16 + MediaQuery.of(context).padding.bottom,
                  child: InkWell(
                    onTap: _showMobileCartSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: ThemeHelper.primaryColor(),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: ThemeHelper.primaryColor().withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Badge(
                            label: Text('$totalItemCount'),
                            backgroundColor: Colors.white,
                            textColor: ThemeHelper.primaryColor(),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            child: const Icon(
                              Icons.shopping_bag,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'View Cart',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                Helper.formatNumberWithPeso(total),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Text(
                            'Checkout',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
