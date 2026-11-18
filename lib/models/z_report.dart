import 'package:sales_management/services/db_helper.dart';
import 'package:sales_management/utils/helper.dart';
import 'package:sqflite/sqflite.dart';

class ZReport {
  String table = DBHelper.tableZReports;

  Future<bool> isClosedForDate(DateTime date) async {
    final db = await DBHelper.initDb();
    final businessDate = Helper.formatDate(date);
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM $table WHERE business_date = ?',
        [businessDate],
      ),
    );
    return (count ?? 0) > 0;
  }

  Future<int> insert(Map<String, dynamic> row) async {
    final db = await DBHelper.initDb();
    return await db.insert(table, row);
  }

  Future<bool> upsertForDate(DateTime date, Map<String, dynamic> row) async {
    final db = await DBHelper.initDb();
    final businessDate = Helper.formatDate(date);

    final updated = await db.update(
      table,
      row,
      where: 'business_date = ?',
      whereArgs: [businessDate],
    );

    if (updated > 0) {
      return true; // updated existing row
    }

    await db.insert(table, row);
    return false; // inserted new row
  }
}
