import 'package:sales_management/services/db_helper.dart';

class Adjustment {
  String table = 'adjustments';

  Future<bool> insert(Map<String, dynamic> row) async {
    final db = await DBHelper.initDb();

    try {
      final String action = row['action_status'] ?? 'IN';
      final num qty = (row['quantity'] as num?) ?? 0;
      final num currentStock = (row['current_stock'] as num?) ?? 0;
      final int productId = (row['product_id'] as num?)?.toInt() ?? 0;

      num newStock = currentStock;

      if (action == 'IN') {
        newStock = currentStock + qty;
        await db.rawUpdate('''
          UPDATE products
          SET stock = stock + ?
          WHERE id = ?
        ''', [qty, productId]);
      } else if (action == 'OUT' || action == 'SALES') {
        newStock = currentStock - qty;
        await db.rawUpdate('''
          UPDATE products
          SET stock = stock - ?
          WHERE id = ?
        ''', [qty, productId]);
      } else if (action == 'AUDIT' || action == 'SET') {
        newStock = qty;
        await db.rawUpdate('''
          UPDATE products
          SET stock = ?
          WHERE id = ?
        ''', [qty, productId]);
      }

      await db.insert(table, {
        'user_id': row['user_id'],
        'product_id': productId,
        'action_status': action,
        'quantity': qty,
        'current_stock': newStock,
        'reason': row['reason'] ?? '',
        'timestamp': DateTime.now().toIso8601String()
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get summary counts of adjustment records
  Future<Map<String, int>> getAdjustmentSummary() async {
    final db = await DBHelper.initDb();
    final res = await db.rawQuery('''
      SELECT 
        COUNT(*) AS total,
        COALESCE(SUM(CASE WHEN action_status = 'IN' THEN 1 ELSE 0 END), 0) AS in_count,
        COALESCE(SUM(CASE WHEN action_status = 'OUT' OR action_status = 'SALES' THEN 1 ELSE 0 END), 0) AS out_count,
        COALESCE(SUM(CASE WHEN action_status = 'AUDIT' OR action_status = 'SET' THEN 1 ELSE 0 END), 0) AS audit_count
      FROM $table
    ''');

    if (res.isNotEmpty) {
      final row = res.first;
      return {
        'total': (row['total'] as num?)?.toInt() ?? 0,
        'inCount': (row['in_count'] as num?)?.toInt() ?? 0,
        'outCount': (row['out_count'] as num?)?.toInt() ?? 0,
        'auditCount': (row['audit_count'] as num?)?.toInt() ?? 0,
      };
    }

    return {'total': 0, 'inCount': 0, 'outCount': 0, 'auditCount': 0};
  }

  Future<List<Map<String, dynamic>>> getAdjustmentsLogs([
    String? searchQuery,
    String? actionStatus,
  ]) async {
    final db = await DBHelper.initDb();
    final List<String> conditions = [];
    final List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim()}%';
      conditions.add(
        '(b.name LIKE ? OR c.username LIKE ? OR c.fname LIKE ? OR c.lname LIKE ? OR a.reason LIKE ?)',
      );
      whereArgs.addAll([q, q, q, q, q]);
    }

    if (actionStatus != null && actionStatus.isNotEmpty && actionStatus != 'All') {
      if (actionStatus == 'IN') {
        conditions.add("a.action_status = 'IN'");
      } else if (actionStatus == 'OUT') {
        conditions.add("(a.action_status = 'OUT' OR a.action_status = 'SALES')");
      } else if (actionStatus == 'AUDIT') {
        conditions.add("(a.action_status = 'AUDIT' OR a.action_status = 'SET')");
      }
    }

    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

    final query = '''
      SELECT 
        a.*,
        b.name AS product_name,
        b.category AS product_category,
        b.unit AS product_unit,
        b.image_path AS product_image,
        b.stock AS current_live_stock,
        b.low_stock_level,
        b.cost_price,
        b.selling_price,
        c.username AS username,
        c.lname AS lname,
        c.fname AS fname,
        c.mname AS mname,
        c.role AS role
      FROM $table a
      JOIN products b ON a.product_id = b.id
      JOIN users c ON a.user_id = c.id
      $whereClause
      ORDER BY a.timestamp DESC
    ''';

    final List<Map<String, dynamic>> result = await db.rawQuery(query, whereArgs);
    return result;
  }

  Future<List<Map<String, dynamic>>> getRecentAdjustments({int limit = 5}) async {
    final db = await DBHelper.initDb();
    final query = '''
      SELECT 
        a.*,
        b.name AS product_name,
        c.username AS username,
        c.lname AS lname,
        c.fname AS fname,
        c.mname AS mname,
        c.role AS role
      FROM adjustments a
      JOIN products b ON a.product_id = b.id
      JOIN users c ON a.user_id = c.id
      ORDER BY a.timestamp DESC
      LIMIT ?
    ''';

    return await db.rawQuery(query, [limit]);
  }
}
