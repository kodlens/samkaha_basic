import 'package:intl/intl.dart';

class Helper {
  static String formatNumberWithPeso(dynamic amount) {
    final value = amount is num
        ? amount.toDouble()
        : (double.tryParse(amount?.toString() ?? '') ?? 0.0);
    final formatter = NumberFormat('#,##0.00');
    return '₱${formatter.format(value)}';
  }

  static String formatNumber(dynamic amount) {
    final value = amount is num
        ? amount.toDouble()
        : (double.tryParse(amount?.toString() ?? '') ?? 0.0);
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(value);
  }

  static String formatReceiptCurrency(dynamic amount) {
    return 'PHP ${formatNumber(amount)}';
  }

  static String formatDate(DateTime date) {
    final formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(date);
  }

  static String formatDateTime(DateTime date) {
    final formatter = DateFormat('MMM dd, yyyy hh:mm a');
    return formatter.format(date);
  }
}
