import 'package:sales_management/services/db_helper.dart';

class TransactionDetails {
  String table = 'transaction_details';

  Future<int> insert(Map<String, dynamic> row) async {
    final db = await DBHelper.initDb();

    // Remove the current_stock from the row before inserting to transaction_details table
    final newData = {
      'transaction_id': row['transaction_id'],
      'user_id': row['user_id'],
      'product_id': row['product_id'],
      'quantity': row['quantity'],
      'cost_price': row['cost_price'],
      'selling_price': row['selling_price'],
      'line_total': row['line_total'],
      'timestamp': row['timestamp'],
    };

    // Update stock when transaction detail is made
    final productId = row['product_id'];
    final quantity = row['quantity'];
    await db.rawUpdate('''
      UPDATE products
      SET stock = stock - ?
      WHERE id = ?
    ''', [quantity, productId]);

    // Also insert the transaction detail to adjustment table for inventory tracking
    await db.insert('adjustments', {
      'user_id': row['user_id'],
      'product_id': productId,
      'quantity': quantity,
      'action_status': 'SALES',
      'current_stock': row['current_stock'] - quantity,
      'reason': 'Product sold in transaction #${row['transaction_id']}',
      'timestamp': DateTime.now().toIso8601String(),
    });

    return await db.insert(table, newData);
  }

  Future<List<Map<String, dynamic>>> queryByTransactionId(int id) async {
    final db = await DBHelper.initDb();

    return await db.rawQuery('''
      SELECT s.*, p.name AS product_name, p.selling_price AS product_s_price,
      p.cost_price AS product_c_price, p.unit AS product_unit
      FROM $table s
      INNER JOIN products p ON s.product_id = p.id
      WHERE s.transaction_id = ?
      ORDER BY s.id DESC
    ''', [id]);
  }

  Future<List<Map<String, dynamic>>> getTopSellingToday({int limit = 5}) async {
    final db = await DBHelper.initDb();
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay =
        startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

    return await db.rawQuery('''
      SELECT 
        s.product_id,
        p.name AS product_name,
        SUM(s.quantity) AS total_qty,
        SUM(s.line_total) AS total_sales
      FROM $table s
      INNER JOIN products p ON s.product_id = p.id
      WHERE s.timestamp BETWEEN ? AND ?
      GROUP BY s.product_id
      ORDER BY total_qty DESC
      LIMIT ?
    ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String(), limit]);
  }
}
