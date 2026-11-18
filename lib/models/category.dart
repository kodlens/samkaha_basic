import 'package:sales_management/services/db_helper.dart';
import 'package:sqflite/sqflite.dart';

class Category {
  final String table = DBHelper.tableCategories;

  Future<bool> hasCategories() async {
    final db = await DBHelper.initDb();
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $table'),
    );
    return count != null && count > 0;
  }

  // Insert or Update category
  Future<int> insertCategory(Map<String, dynamic> row) async {
    final db = await DBHelper.initDb();
    final int id = (row['id'] as num?)?.toInt() ?? 0;
    if (id > 0) {
      return await db.update(
        table,
        {'category': row['category']},
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      return await db.insert(table, {'category': row['category']});
    }
  }

  // Get all categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await DBHelper.initDb();
    return await db.query(table, orderBy: 'id DESC');
  }

  // Get categories with linked product count
  Future<List<Map<String, dynamic>>> getCategoriesWithProductCount() async {
    final db = await DBHelper.initDb();
    return await db.rawQuery('''
      SELECT c.id, c.category, COUNT(p.id) AS product_count
      FROM $table c
      LEFT JOIN ${DBHelper.tableProducts} p ON c.category = p.category
      GROUP BY c.id, c.category
      ORDER BY c.id DESC
    ''');
  }

  // Count products associated with a specific category
  Future<int> countProductsInCategory(String categoryName) async {
    final db = await DBHelper.initDb();
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM ${DBHelper.tableProducts} WHERE category = ?',
      [categoryName],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Check if a category name already exists (excluding current id for edits)
  Future<bool> categoryExists(String categoryName, [int? excludeId]) async {
    final db = await DBHelper.initDb();
    String query = 'SELECT COUNT(*) FROM $table WHERE LOWER(category) = LOWER(?)';
    List<dynamic> args = [categoryName.trim()];
    if (excludeId != null && excludeId > 0) {
      query += ' AND id != ?';
      args.add(excludeId);
    }
    final count = Sqflite.firstIntValue(await db.rawQuery(query, args));
    return count != null && count > 0;
  }

  // Delete category
  Future<int> deleteCategory(int id) async {
    final db = await DBHelper.initDb();
    return await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
