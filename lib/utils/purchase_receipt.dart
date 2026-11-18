import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import 'package:sales_management/utils/helper.dart';

class PurchaseReceipt {

  final List<Map<String, dynamic>> cart;

  final int transactionId;
  final double totalAmount;
  final double paymentAmount;
  final double change;
  final String paymentMethod;

  PurchaseReceipt({
    required this.transactionId,
    required this.cart,
    required this.totalAmount,
    required this.paymentAmount,
    required this.change,
    this.paymentMethod = 'Cash',
  });


  Future<List<int>> buildReceiptBytes() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final bytes = <int>[];

    bytes.addAll(
      generator.text(
        'SamKaha POS',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        ),
      ),
    );
    bytes.addAll(
      generator.text(
        'Official Receipt',
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(
      generator.text(
        'Date: $now',
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(
      generator.text(
        'Transaction ID: ${transactionId.toString().padLeft(6, '0')}',
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(generator.hr(ch: '-'));

    bytes.addAll(
      generator.row([
        PosColumn(text: 'Item', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(
          text: 'Qty',
          width: 2,
          styles: const PosStyles(align: PosAlign.center, bold: true),
        ),
        PosColumn(
          text: 'Total',
          width: 4,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]),
    );

    for (final item in cart) {
      final name = '${item['name'] ?? ''}'.trim();
      const maxNameLength = 24;
      final safeName = name.length > maxNameLength
          ? '${name.substring(0, maxNameLength - 3)}...'
          : name;
      final quantity = (item['quantity'] as num?)?.toDouble() ?? 0;
      final price = (item['selling_price'] as num?)?.toDouble() ?? 0;
      final lineTotal = quantity * price;

      bytes.addAll(
        generator.text(
          safeName,
          styles: const PosStyles(bold: true),
        ),
      );
      bytes.addAll(
        generator.row([
          PosColumn(
            text: '${quantity.toStringAsFixed(0)} x ${Helper.formatReceiptCurrency(price)}',
            width: 8,
          ),
          PosColumn(
            text: Helper.formatReceiptCurrency(lineTotal),
            width: 4,
            styles: const PosStyles(align: PosAlign.right, bold: true),
          ),
        ]),
      );
    }

    bytes.addAll(generator.hr(ch: '-'));
    bytes.addAll(
      generator.row([
        PosColumn(text: 'TOTAL', width: 8, styles: const PosStyles(bold: true)),
        PosColumn(
          text: Helper.formatReceiptCurrency(totalAmount),
          width: 4,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]),
    );
    bytes.addAll(
      generator.row([
        PosColumn(text: paymentMethod, width: 8),
        PosColumn(
          text: Helper.formatReceiptCurrency(paymentAmount),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]),
    );
    bytes.addAll(
      generator.row([
        PosColumn(text: 'Change', width: 8),
        PosColumn(
          text: Helper.formatReceiptCurrency(change),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]),
    );
    bytes.addAll(generator.hr(ch: '-'));
    bytes.addAll(
      generator.text(
        'Thank you!',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
    );
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    return bytes;
  }
}
