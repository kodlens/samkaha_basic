import 'package:sales_management/services/db_helper.dart';
import 'package:sqflite/sqflite.dart';

class Product {

  String table = 'products';

  int version = 1;
  String dbName = 'pos.db';
  Database? db;



    // Insert product
  Future<int> insertProduct(Map<String, dynamic> row) async {
    final db = await DBHelper.initDb();
    return row['id'] > 0 ? await db.update(table, row, where: 'id = ?', whereArgs: [row['id']]) : await db.insert(table, {
      'barcode': row['barcode'],
      'category': row['category'],
      'name': row['name'],
      'unit': row['unit'],
      'cost_price': row['cost_price'],
      'selling_price': row['selling_price'],
      'low_stock_level': row['low_stock_level'],
      'image_path': row['image_path']
    });
  }


  Future<bool> hasProducts() async {
    final db = await DBHelper.initDb();
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $table'));
    return count != null && count > 0;
  }

  
  // Get all products with optional search query, category, and status filter
  Future<List<Map<String, dynamic>>> getProducts([
    String? searchQuery,
    String? category,
    String? status,
  ]) async {
    final db = await DBHelper.initDb();
    final List<String> conditions = [];
    final List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim()}%';
      conditions.add('(name LIKE ? OR barcode LIKE ?)');
      whereArgs.add(q);
      whereArgs.add(q);
    }

    if (category != null && category.isNotEmpty && category != 'All') {
      conditions.add('category = ?');
      whereArgs.add(category);
    }

    if (status != null && status.isNotEmpty && status != 'All') {
      if (status == 'In Stock') {
        conditions.add('stock > low_stock_level');
      } else if (status == 'Low Stock') {
        conditions.add('stock > 0 AND stock <= low_stock_level');
      } else if (status == 'Out of Stock') {
        conditions.add('stock <= 0');
      }
    }

    final whereClause = conditions.isNotEmpty ? conditions.join(' AND ') : null;

    return await db.query(
      table,
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'id DESC',
    );
  }

  // Get summary counts (total, inStock, lowStock, outOfStock)
  Future<Map<String, int>> getProductSummary() async {
    final db = await DBHelper.initDb();
    final total = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $table'),
    ) ?? 0;

    final outOfStock = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $table WHERE stock <= 0'),
    ) ?? 0;

    final lowStock = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM $table WHERE stock > 0 AND stock <= low_stock_level',
      ),
    ) ?? 0;

    final inStock = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $table WHERE stock > low_stock_level'),
    ) ?? 0;

    return {
      'total': total,
      'inStock': inStock,
      'lowStock': lowStock,
      'outOfStock': outOfStock,
    };
  }

  // Check if a product with the same name exists
  Future<bool> productExists(String name, {int? excludeId}) async {
    final db = await DBHelper.initDb();
    final result = await db.query(
      table,
      where: excludeId != null
          ? 'LOWER(name) = ? AND id != ?'
          : 'LOWER(name) = ?',
      whereArgs: excludeId != null
          ? [name.trim().toLowerCase(), excludeId]
          : [name.trim().toLowerCase()],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // Count number of transaction sales records referencing this product
  Future<int> countProductSales(int productId) async {
    final db = await DBHelper.initDb();
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DBHelper.tableTransactionDetails} WHERE product_id = ?',
        [productId],
      ),
    );
    return count ?? 0;
  }

  // Get complete inventory valuation and health breakdown
  Future<Map<String, dynamic>> getInventoryValuationSummary() async {
    final db = await DBHelper.initDb();
    final res = await db.rawQuery('''
      SELECT 
        COUNT(*) AS total_items,
        COALESCE(SUM(stock), 0) AS total_units,
        COALESCE(SUM(stock * cost_price), 0) AS total_cost_value,
        COALESCE(SUM(stock * selling_price), 0) AS total_retail_value,
        COALESCE(SUM(CASE WHEN stock <= 0 THEN 1 ELSE 0 END), 0) AS out_of_stock,
        COALESCE(SUM(CASE WHEN stock > 0 AND stock <= low_stock_level THEN 1 ELSE 0 END), 0) AS low_stock,
        COALESCE(SUM(CASE WHEN stock > low_stock_level THEN 1 ELSE 0 END), 0) AS in_stock
      FROM $table
    ''');

    if (res.isNotEmpty) {
      final row = res.first;
      return {
        'totalItems': (row['total_items'] as num?)?.toInt() ?? 0,
        'totalUnits': (row['total_units'] as num?)?.toDouble() ?? 0.0,
        'totalCostValue': (row['total_cost_value'] as num?)?.toDouble() ?? 0.0,
        'totalRetailValue': (row['total_retail_value'] as num?)?.toDouble() ?? 0.0,
        'outOfStock': (row['out_of_stock'] as num?)?.toInt() ?? 0,
        'lowStock': (row['low_stock'] as num?)?.toInt() ?? 0,
        'inStock': (row['in_stock'] as num?)?.toInt() ?? 0,
      };
    }

    return {
      'totalItems': 0,
      'totalUnits': 0.0,
      'totalCostValue': 0.0,
      'totalRetailValue': 0.0,
      'outOfStock': 0,
      'lowStock': 0,
      'inStock': 0,
    };
  }
  
  //get product by status and search query
  Future<List<Map<String, dynamic>>> getProductsByStatus(String status, String? searchQuery) async {
    final db = await DBHelper.initDb();

    //status are In Stock, Out of Stock, All, Low Stock
    if (status == 'All') {
      return await getProducts(searchQuery);
    }

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (status == 'In Stock') {
      whereClause = 'stock > 0';
    } else if (status == 'Out of Stock') {
      whereClause = 'stock <= 0';
    } else if (status == 'Low Stock') {
      whereClause = 'stock > 0 AND stock <= low_stock_level';
    } 

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause += ('${whereClause.isNotEmpty ? ' AND ' : ''} name LIKE ?');
      whereArgs.add('%$searchQuery%');
    }

    return await db.query(
      table,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'id DESC',
    );

  }

  //delete product
  Future<int> deleteProduct(int id) async {
    final db = await DBHelper.initDb();
    // returns the number of rows deleted
    return await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getLowStockCount() async {
    final db = await DBHelper.initDb();
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM $table WHERE stock > 0 AND stock <= low_stock_level',
      ),
    );
    return count ?? 0;
  }

  Future<List<Map<String, dynamic>>> getLowStockItemsList({int limit = 5}) async {
    final db = await DBHelper.initDb();
    return await db.rawQuery('''
      SELECT id, name, category, stock, low_stock_level, unit
      FROM $table
      WHERE stock <= low_stock_level
      ORDER BY stock ASC
      LIMIT ?
    ''', [limit]);
  }




}
