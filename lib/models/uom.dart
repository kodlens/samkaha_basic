import 'package:sales_management/services/db_helper.dart';
import 'package:sqflite/sqflite.dart';

class Uom {
  final String table = DBHelper.tableUoms;

  // Insert or Update UOM
  Future<int> insertUom(Map<String, dynamic> row) async {
    final db = await DBHelper.initDb();
    final int id = (row['id'] as num?)?.toInt() ?? 0;
    final String name = (row['uom'] ?? '').toString().trim();

    if (id > 0) {
      return await db.update(
        table,
        {'uom': name},
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      return await db.insert(table, {'uom': name});
    }
  }

  // Get all UOMs
  Future<List<Map<String, dynamic>>> getUoms() async {
    final db = await DBHelper.initDb();
    return await db.query(table, orderBy: 'id DESC');
  }

  // Get UOMs with count of linked products
  Future<List<Map<String, dynamic>>> getUomsWithProductCount() async {
    final db = await DBHelper.initDb();
    return await db.rawQuery('''
      SELECT u.id, u.uom, COUNT(p.id) AS product_count
      FROM $table u
      LEFT JOIN ${DBHelper.tableProducts} p ON LOWER(u.uom) = LOWER(p.unit)
      GROUP BY u.id, u.uom
      ORDER BY u.id DESC
    ''');
  }

  // Check if a UOM name already exists
  Future<bool> uomExists(String uomName, [int? excludeId]) async {
    final db = await DBHelper.initDb();
    String query = 'SELECT COUNT(*) FROM $table WHERE LOWER(uom) = LOWER(?)';
    List<dynamic> args = [uomName.trim()];
    if (excludeId != null && excludeId > 0) {
      query += ' AND id != ?';
      args.add(excludeId);
    }
    final count = Sqflite.firstIntValue(await db.rawQuery(query, args));
    return count != null && count > 0;
  }

  // Count products using a specific unit
  Future<int> countProductsInUom(String uomName) async {
    final db = await DBHelper.initDb();
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM ${DBHelper.tableProducts} WHERE LOWER(unit) = LOWER(?)',
      [uomName.trim()],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Delete UOM
  Future<int> deleteUom(int id) async {
    final db = await DBHelper.initDb();
    return await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> hasUoms() async {
    final db = await DBHelper.initDb();
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $table'),
    );
    return count != null && count > 0;
  }
}
