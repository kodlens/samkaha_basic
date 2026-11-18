import 'package:sales_management/services/db_helper.dart';

class Expense {
  final String table = DBHelper.tableExpenses;

  Future<int> insert(Map<String, dynamic> row) async {
    final db = await DBHelper.initDb();
    return await db.insert(table, row);
  }

  Future<int> update(Map<String, dynamic> row) async {
    final db = await DBHelper.initDb();
    final int id = row['id'];
    return await db.update(table, row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async {
    final db = await DBHelper.initDb();
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> queryAll() async {
    final db = await DBHelper.initDb();
    return await db.query(table, orderBy: 'date DESC, id DESC');
  }

  Future<List<Map<String, dynamic>>> queryByDate(DateTime date) async {
    final db = await DBHelper.initDb();
    final dateStr = date.toIso8601String().split('T')[0];
    return await db.query(
      table,
      where: 'date = ?',
      whereArgs: [dateStr],
      orderBy: 'id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> queryByDateRange(
    DateTime fromDate,
    DateTime toDate,
  ) async {
    final db = await DBHelper.initDb();
    final fromDateStr = fromDate.toIso8601String().split('T')[0];
    final toDateStr = toDate.toIso8601String().split('T')[0];
    return await db.query(
      table,
      where: 'date BETWEEN ? AND ?',
      whereArgs: [fromDateStr, toDateStr],
      orderBy: 'date DESC, id DESC',
    );
  }

  Future<double> getTodayTotal() async {
    final db = await DBHelper.initDb();
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM $table WHERE date = ?',
      [todayStr],
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  Future<double> getTotalByDateRange(DateTime fromDate, DateTime toDate) async {
    final db = await DBHelper.initDb();
    final fromDateStr = fromDate.toIso8601String().split('T')[0];
    final toDateStr = toDate.toIso8601String().split('T')[0];
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM $table WHERE date BETWEEN ? AND ?',
      [fromDateStr, toDateStr],
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }
}
