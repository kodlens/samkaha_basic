import 'package:sales_management/models/payment_method.dart';
import 'package:sales_management/services/db_helper.dart';
import 'package:sqflite/sqflite.dart';

class PaymentMethodSeed {
  // Standard initial payment methods
  final List<Map<String, dynamic>> paymentMethods = [
    {
      'name': 'Cash',
      'type': 'cash',
      'is_active': 1,
    },
    {
      'name': 'GCash',
      'type': 'e-wallet',
      'is_active': 1,
    },
    {
      'name': 'Maya',
      'type': 'e-wallet',
      'is_active': 1,
    },
    {
      'name': 'Bank Transfer',
      'type': 'bank',
      'is_active': 1,
    },
    {
      'name': 'Credit/Debit Card',
      'type': 'card',
      'is_active': 1,
    },
  ];

  Future<void> paymentMethodSeed() async {
    final exists = await PaymentMethod().hasPaymentMethods();

    if (!exists) {
      for (var method in paymentMethods) {
        await PaymentMethod().insert({
          'name': method['name'],
          'type': method['type'],
          'is_active': method['is_active'],
        });
      }
    } else {
      // Ensure GCash is specifically present in case previous seed missed it
      final hasGcash = await PaymentMethod().nameExists('GCash');
      if (!hasGcash) {
        await PaymentMethod().insert({
          'name': 'GCash',
          'type': 'e-wallet',
          'is_active': 1,
        });
      }
    }

    // Seed a sample GCash payment transaction if no transactions exist yet
    await seedSampleGcashPayment();
  }

  /// Seeds a sample GCash transaction so the user can immediately observe
  /// the Cash on Hand vs E-Payments separation in the dashboard & transaction log.
  Future<void> seedSampleGcashPayment() async {
    final db = await DBHelper.initDb();

    // Only seed if no GCash transaction exists yet
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM ${DBHelper.tableTransactions} WHERE payment_method = ?',
        ['GCash'],
      ),
    );

    if (count == null || count == 0) {
      final userResult = await db.query(DBHelper.tableUsers, limit: 1);
      final productResult = await db.query(DBHelper.tableProducts, limit: 1);

      final int userId = userResult.isNotEmpty ? (userResult.first['id'] as int) : 1;
      final int productId = productResult.isNotEmpty ? (productResult.first['id'] as int) : 1;
      final double sellingPrice = productResult.isNotEmpty
          ? ((productResult.first['selling_price'] as num?)?.toDouble() ?? 100.0)
          : 100.0;
      final double costPrice = productResult.isNotEmpty
          ? ((productResult.first['cost_price'] as num?)?.toDouble() ?? 70.0)
          : 70.0;
      const double qty = 2.0;
      final double total = sellingPrice * qty;
      final now = DateTime.now().toIso8601String();

      final txId = await db.insert(DBHelper.tableTransactions, {
        'user_id': userId,
        'customer_name': 'GCash Test Customer',
        'quantity': qty.toInt(),
        'payment': total,
        'total': total,
        'payment_method': 'GCash',
        'timestamp': now,
      });

      await db.insert(DBHelper.tableTransactionDetails, {
        'transaction_id': txId,
        'user_id': userId,
        'product_id': productId,
        'quantity': qty,
        'cost_price': costPrice,
        'selling_price': sellingPrice,
        'line_total': total,
        'timestamp': now,
      });
    }
  }
}
