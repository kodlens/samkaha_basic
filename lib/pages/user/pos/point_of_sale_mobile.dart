import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sales_management/models/product.dart';

class PointOfSaleMobile extends StatefulWidget {
  const PointOfSaleMobile({super.key});

  @override
  State<PointOfSaleMobile> createState() => _PointOfSaleMobileState();
}

class _PointOfSaleMobileState extends State<PointOfSaleMobile> {
  Future<List<Map<String, dynamic>>>? _future;

  // Cart
  final List<Map<String, dynamic>> cart = [];

  @override
  void initState() {
    super.initState();
    _future = Product().getProducts(null); // make sure this exists
  }

  // ================= CART FUNCTIONS =================

  void addToCart(Map<String, dynamic> product) {
    setState(() {
      final index = cart.indexWhere((item) => item['id'] == product['id']);
      if (index >= 0) {
        cart[index]['quantity'] += 1;
      } else {
        cart.add({...product, 'quantity': 1});
      }
    });
  }

  void removeFromCart(int index) {
    if (index < 0 || index >= cart.length) return;
    setState(() {
      cart.removeAt(index);
    });
  }

  void incrementQuantity(int index) {
    if (index < 0 || index >= cart.length) return;
    setState(() {
      cart[index]['quantity'] += 1;
    });
  }

  void decrementQuantity(int index) {
    if (index < 0 || index >= cart.length) return;
    setState(() {
      if (cart[index]['quantity'] > 1) {
        cart[index]['quantity'] -= 1;
      } else {
        cart.removeAt(index);
      }
    });
  }

  double get total => cart.fold(
    0,
    (sum, item) => sum + (item['selling_price'] * item['quantity']),
  );

  // ================= MODAL =================

  void _showProductModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 10),

              const Text(
                "Select Product",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const Divider(),

              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No products found'));
                    }

                    final products = snapshot.data!;

                    return ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];

                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child:
                                  product['image_path'] != null &&
                                      product['image_path'] != ''
                                  ? Image.file(
                                      File(product['image_path']),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.broken_image,
                                            );
                                          },
                                    )
                                  : const Icon(Icons.image),
                            ),
                          ),
                          title: Text(product['name'] ?? 'No name'),
                          subtitle: Text('₱${product['selling_price'] ?? 0}'),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: Colors.green,
                            ),
                            onPressed: () {
                              addToCart(product);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Point of Sale',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 🔥 BUTTON
            Padding(
              padding: const EdgeInsets.all(10),
              child: ElevatedButton(
                onPressed: _showProductModal,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Select Products"),
              ),
            ),

            // 🔥 CART LIST
            Expanded(
              child: cart.isEmpty
                  ? const Center(child: Text("No items in cart"))
                  : ListView.builder(
                      itemCount: cart.length,
                      itemBuilder: (context, index) {
                        final item = cart[index];

                        return ListTile(
                          title: Text(item['name']),
                          subtitle: Text(
                            '₱${item['selling_price']} x ${item['quantity']}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => decrementQuantity(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => incrementQuantity(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => removeFromCart(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // 🔥 TOTAL
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey[200]),
              child: Text(
                'Total: ₱${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
