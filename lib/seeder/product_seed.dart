import 'package:sales_management/models/product.dart';

class ProductSeed {
  
  final List<Map<String, dynamic>> products = [
    // ☕ Starter Sample Products (Basic Edition)
    {'id': 1, 'name': 'Iced Caramel Macchiato 16oz', 'selling_price': 120.00, 'cost_price': 70.00, 'unit': 'OZ', 'low_stock_level': 10, 'category': 'Beverages'},
    {'id': 2, 'name': 'Chocolate Croissant', 'selling_price': 65.00, 'cost_price': 40.00, 'unit': 'PCS', 'low_stock_level': 10, 'category': 'Food'},
  ];

  void productSeed() async {
    final exists = await Product().hasProducts();
    if(!exists){
      for (var product in products) {
        await Product().insertProduct({
          'id': 0,
          'name': product['name'],
          'selling_price': product['selling_price'],
          'cost_price': product['cost_price'],
          'unit': product['unit'],
          'low_stock_level': product['low_stock_level'],
          'category': product['category'],
        });
      }
    }
  }

}