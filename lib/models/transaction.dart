import 'package:sales_management/services/db_helper.dart';

class Transaction {
  String table = 'transactions';

  Future<int> insert(Map<String, dynamic> row) async {
    final db = await DBHelper.initDb();
    return await db.insert(table, row);
  }

  Future<int> update(Map<String, dynamic> row) async {
    final db = await DBHelper.initDb();
    int id = row['id'];
    return await db.update(table, row, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> queryAll() async {
    final db = await DBHelper.initDb();
    return await db.query(table, orderBy: 'id DESC');
  }

  Future<int> delete(int id) async {
    final db = await DBHelper.initDb();
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> queryByDateRange(
    DateTime fromDate,
    DateTime toDate,
  ) async {
    final db = await DBHelper.initDb();
    final fromDateStr = '${fromDate.toIso8601String().split('T')[0]}T00:00:00.000';
    final toDateStr = '${toDate.toIso8601String().split('T')[0]}T23:59:59.999';
    return await db.query(
      table,
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [fromDateStr, toDateStr],
      orderBy: 'id DESC',
    );
  }

  // Enhanced query with filters: date range, search query, staff user ID
  Future<List<Map<String, dynamic>>> queryTransactions({
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
    int? userId,
    String? paymentMethod,
  }) async {
    final db = await DBHelper.initDb();
    final List<String> conditions = [];
    final List<dynamic> whereArgs = [];

    if (fromDate != null && toDate != null) {
      final fromStr = '${fromDate.toIso8601String().split('T')[0]}T00:00:00.000';
      final toStr = '${toDate.toIso8601String().split('T')[0]}T23:59:59.999';
      conditions.add('t.timestamp BETWEEN ? AND ?');
      whereArgs.add(fromStr);
      whereArgs.add(toStr);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim()}%';
      conditions.add('(t.customer_name LIKE ? OR CAST(t.id AS TEXT) LIKE ?)');
      whereArgs.add(q);
      whereArgs.add(q);
    }

    if (userId != null && userId > 0) {
      conditions.add('t.user_id = ?');
      whereArgs.add(userId);
    }

    if (paymentMethod != null && paymentMethod.isNotEmpty && paymentMethod != 'All') {
      conditions.add('t.payment_method = ?');
      whereArgs.add(paymentMethod);
    }

    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

    final query = '''
      SELECT 
        t.*,
        u.username AS cashier_username,
        u.fname AS cashier_fname,
        u.lname AS cashier_lname,
        u.role AS cashier_role
      FROM $table t
      LEFT JOIN ${DBHelper.tableUsers} u ON t.user_id = u.id
      $whereClause
      ORDER BY t.id DESC
    ''';

    return await db.rawQuery(query, whereArgs);
  }

  // Executive summary for filtered transactions
  Future<Map<String, dynamic>> queryTransactionSummary({
    DateTime? fromDate,
    DateTime? toDate,
    String? searchQuery,
    int? userId,
    String? paymentMethod,
  }) async {
    final db = await DBHelper.initDb();
    final List<String> conditions = [];
    final List<dynamic> whereArgs = [];

    if (fromDate != null && toDate != null) {
      final fromStr = '${fromDate.toIso8601String().split('T')[0]}T00:00:00.000';
      final toStr = '${toDate.toIso8601String().split('T')[0]}T23:59:59.999';
      conditions.add('timestamp BETWEEN ? AND ?');
      whereArgs.add(fromStr);
      whereArgs.add(toStr);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim()}%';
      conditions.add('(customer_name LIKE ? OR CAST(id AS TEXT) LIKE ?)');
      whereArgs.add(q);
      whereArgs.add(q);
    }

    if (userId != null && userId > 0) {
      conditions.add('user_id = ?');
      whereArgs.add(userId);
    }

    if (paymentMethod != null && paymentMethod.isNotEmpty && paymentMethod != 'All') {
      conditions.add('payment_method = ?');
      whereArgs.add(paymentMethod);
    }

    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) AS tx_count,
        COALESCE(SUM(total), 0) AS total_sales,
        COALESCE(SUM(quantity), 0) AS total_items,
        COALESCE(SUM(CASE WHEN LOWER(payment_method) = 'cash' OR payment_method IS NULL THEN total ELSE 0 END), 0) AS cash_sales,
        COALESCE(SUM(CASE WHEN LOWER(payment_method) != 'cash' AND payment_method IS NOT NULL THEN total ELSE 0 END), 0) AS epayment_sales,
        MIN(timestamp) AS first_tx,
        MAX(timestamp) AS last_tx
      FROM $table
      $whereClause
    ''', whereArgs);

    if (result.isNotEmpty) {
      final row = result.first;
      final totalSales = (row['total_sales'] as num?)?.toDouble() ?? 0.0;
      final cashSales = (row['cash_sales'] as num?)?.toDouble() ?? 0.0;
      final epaymentSales = (row['epayment_sales'] as num?)?.toDouble() ?? 0.0;
      final txCount = (row['tx_count'] as num?)?.toInt() ?? 0;
      final totalItems = (row['total_items'] as num?)?.toInt() ?? 0;
      final avgTicket = txCount > 0 ? totalSales / txCount : 0.0;

      return {
        'totalSales': totalSales,
        'cashSales': cashSales,
        'epaymentSales': epaymentSales,
        'txCount': txCount,
        'totalItems': totalItems,
        'avgTicket': avgTicket,
      };
    }

    return {
      'totalSales': 0.0,
      'cashSales': 0.0,
      'epaymentSales': 0.0,
      'txCount': 0,
      'totalItems': 0,
      'avgTicket': 0.0,
    };
  }

  Future<double> getTodaySalesTotal() async {
    final db = await DBHelper.initDb();
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay =
        startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

    final result = await db.rawQuery(
      'SELECT SUM(total) as total FROM $table WHERE timestamp BETWEEN ? AND ?',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );

    final value = result.isNotEmpty ? result.first['total'] : null;
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Future<Map<String, double>> getXReportToday() async {
    final db = await DBHelper.initDb();
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay =
        startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

    final result = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS tx_count,
        COALESCE(SUM(total), 0) AS total_sales,
        COALESCE(SUM(payment), 0) AS total_payment,
        COALESCE(SUM(quantity), 0) AS total_qty
      FROM $table
      WHERE timestamp BETWEEN ? AND ?
      ''',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );

    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return double.tryParse(value.toString()) ?? 0.0;
    }

    final row = result.isNotEmpty ? result.first : {};
    final totalSales = toDouble(row['total_sales']);
    final totalPayment = toDouble(row['total_payment']);
    final totalQty = toDouble(row['total_qty']);
    final txCount = toDouble(row['tx_count']);
    final avgTicket = txCount > 0 ? totalSales / txCount : 0.0;

    return {
      'total_sales': totalSales,
      'total_payment': totalPayment,
      'total_qty': totalQty,
      'tx_count': txCount,
      'avg_ticket': avgTicket,
    };
  }

  // Get sales breakdown including cash sales, e-payments sales, and payment method groupings
  Future<Map<String, dynamic>> getTodaySalesBreakdown() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay =
        startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

    return await getSalesBreakdownByDateRange(startOfDay, endOfDay);
  }

  Future<Map<String, dynamic>> getSalesBreakdownByDateRange(
    DateTime fromDate,
    DateTime toDate,
  ) async {
    final db = await DBHelper.initDb();
    final fromStr = fromDate.toIso8601String();
    final toStr = toDate.toIso8601String();

    final result = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS tx_count,
        COALESCE(SUM(total), 0) AS total_sales,
        COALESCE(SUM(payment), 0) AS total_payment,
        COALESCE(SUM(quantity), 0) AS total_qty,
        COALESCE(SUM(CASE WHEN LOWER(payment_method) = 'cash' OR payment_method IS NULL THEN total ELSE 0 END), 0) AS cash_sales,
        COALESCE(SUM(CASE WHEN LOWER(payment_method) != 'cash' AND payment_method IS NOT NULL THEN total ELSE 0 END), 0) AS epayment_sales,
        MIN(timestamp) AS first_tx,
        MAX(timestamp) AS last_tx
      FROM $table
      WHERE timestamp BETWEEN ? AND ?
      ''',
      [fromStr, toStr],
    );

    // Breakdown per payment method
    final methodBreakdown = await db.rawQuery(
      '''
      SELECT
        COALESCE(payment_method, 'Cash') AS method,
        COUNT(*) AS count,
        COALESCE(SUM(total), 0) AS total
      FROM $table
      WHERE timestamp BETWEEN ? AND ?
      GROUP BY COALESCE(payment_method, 'Cash')
      ORDER BY total DESC
      ''',
      [fromStr, toStr],
    );

    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return double.tryParse(value.toString()) ?? 0.0;
    }

    final row = result.isNotEmpty ? result.first : {};
    final totalSales = toDouble(row['total_sales']);
    final cashSales = toDouble(row['cash_sales']);
    final epaymentSales = toDouble(row['epayment_sales']);
    final totalPayment = toDouble(row['total_payment']);
    final totalQty = toDouble(row['total_qty']);
    final txCount = toDouble(row['tx_count']);
    final avgTicket = txCount > 0 ? totalSales / txCount : 0.0;

    return {
      'total_sales': totalSales,
      'cash_sales': cashSales,
      'epayment_sales': epaymentSales,
      'total_payment': totalPayment,
      'total_qty': totalQty,
      'tx_count': txCount,
      'avg_ticket': avgTicket,
      'methods': methodBreakdown,
      'first_tx': row['first_tx']?.toString(),
      'last_tx': row['last_tx']?.toString(),
    };
  }
}
