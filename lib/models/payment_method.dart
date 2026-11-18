import 'package:sales_management/services/db_helper.dart';
import 'package:sqflite/sqflite.dart';

class PaymentMethod {
  final String table = DBHelper.tablePaymentMethods;

  // Query all payment methods, optionally filtering active ones
  Future<List<Map<String, dynamic>>> getPaymentMethods({bool activeOnly = false}) async {
    final db = await DBHelper.initDb();
    if (activeOnly) {
      return await db.query(
        table,
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: "CASE WHEN name = 'Cash' THEN 0 ELSE 1 END, name ASC",
      );
    }
    return await db.query(
      table,
      orderBy: "CASE WHEN name = 'Cash' THEN 0 ELSE 1 END, name ASC",
    );
  }

  // Convenience method for active payment methods
  Future<List<Map<String, dynamic>>> getActiveMethods() async {
    return await getPaymentMethods(activeOnly: true);
  }

  // Insert a new payment method
  Future<int> insert(Map<String, dynamic> row) async {
    final db = await DBHelper.initDb();
    return await db.insert(table, {
      'name': row['name']?.toString().trim(),
      'type': row['type'] ?? 'cash',
      'is_active': row['is_active'] ?? 1,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Update existing payment method
  Future<int> update(Map<String, dynamic> row) async {
    final db = await DBHelper.initDb();
    final id = row['id'];
    return await db.update(
      table,
      {
        'name': row['name']?.toString().trim(),
        'type': row['type'] ?? 'cash',
        'is_active': row['is_active'] ?? 1,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Toggle active status
  Future<int> toggleActive(int id, bool isActive) async {
    final db = await DBHelper.initDb();
    return await db.update(
      table,
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Check if a method is in use by transactions
  Future<int> countTransactions(String methodName) async {
    final db = await DBHelper.initDb();
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM ${DBHelper.tableTransactions} WHERE payment_method = ?',
      [methodName],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Safe delete: prevent deleting 'Cash' or methods currently referenced by transactions
  Future<bool> delete(int id, String name) async {
    if (name.trim().toLowerCase() == 'cash') {
      return false; // Cash cannot be deleted
    }
    final usage = await countTransactions(name);
    final db = await DBHelper.initDb();
    if (usage > 0) {
      // If transactions exist, soft-disable it rather than breaking foreign data integrity
      await db.update(table, {'is_active': 0}, where: 'id = ?', whereArgs: [id]);
      return false; // Soft disabled
    }
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
    return true; // Hard deleted
  }

  // Check if any payment methods exist
  Future<bool> hasPaymentMethods() async {
    final db = await DBHelper.initDb();
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $table'),
    );
    return count != null && count > 0;
  }

  // Check if name already exists
  Future<bool> nameExists(String name, {int? excludeId}) async {
    final db = await DBHelper.initDb();
    final result = await db.query(
      table,
      where: excludeId != null ? 'LOWER(name) = ? AND id != ?' : 'LOWER(name) = ?',
      whereArgs: excludeId != null ? [name.trim().toLowerCase(), excludeId] : [name.trim().toLowerCase()],
    );
    return result.isNotEmpty;
  }
}
