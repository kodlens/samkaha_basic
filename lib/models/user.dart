import 'package:sales_management/services/db_helper.dart';
import 'package:sqflite/sqflite.dart';

class User {

  int version = 1;
  String dbName = 'pos.db';
  Database? db;
  String table = 'users';




  Future<bool> hasUsers() async {
    final db = await DBHelper.initDb();
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $table'));
    return count != null && count > 0;
  }

  Future<Map<String, dynamic>> authenticate(String username, String password) async {
    final db = await DBHelper.initDb();
    final result = await db.query(
      table,
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return {
        'login': true,
        'id': result.first['id'],
        'username': result.first['username'],
        'fname': result.first['fname'],
        'lname': result.first['lname'],
        'mname': result.first['mname'],
        'role': result.first['role'],
        'sex': result.first['sex']
      };
    }

    return {
      'login': false,
    };
  }

  Future<int> insertUser(Map<String, dynamic> row) async {
    final db = await DBHelper.initDb();

    if (row['id'] > 0) {
      final updated = Map<String, dynamic>.from(row);
      if ((updated['password'] ?? '').toString().isEmpty) {
        updated.remove('password'); // keep existing password if not provided
      }
      return await db.update(
        table,
        updated,
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }

    return await db.insert(table, {
      'username': row['username'],
      'password': row['password'],
      'fname': row['fname'],
      'mname': row['mname'],
      'lname': row['lname'],
      'sex': row['sex'],
      'role': row['role'],
    });
  }

   Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await DBHelper.initDb();

    return await db.query(table, 
      where: 'role != ?', 
      whereArgs: ['superadmin'],
      orderBy: 'id DESC',);
  }



  Future<int> deleteUser(int id) async {
    final db = await DBHelper.initDb();
    // returns the number of rows deleted
    return await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> isUsernameTaken(String username, {int? excludeId}) async {
    final db = await DBHelper.initDb();
    final result = await db.query(
      table,
      where: excludeId != null && excludeId > 0
          ? 'LOWER(username) = ? AND id != ?'
          : 'LOWER(username) = ?',
      whereArgs: excludeId != null && excludeId > 0
          ? [username.trim().toLowerCase(), excludeId]
          : [username.trim().toLowerCase()],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<int> updatePassword({required int id, required String newPassword}) async {
    final db = await DBHelper.initDb();
    return await db.update(
      table,
      {'password': newPassword},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  


}
