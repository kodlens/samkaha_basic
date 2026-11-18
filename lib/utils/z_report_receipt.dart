import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import 'package:sales_management/utils/helper.dart';

class ZReportReceipt {
  final double totalSales;
  final double totalPayment;
  final double totalQty;
  final double txCount;
  final double avgTicket;
  final DateTime? from;
  final DateTime? to;
  final String storeName;
  final String? closedBy;

  ZReportReceipt({
    required this.totalSales,
    required this.totalPayment,
    required this.totalQty,
    required this.txCount,
    required this.avgTicket,
    this.from,
    this.to,
    this.storeName = 'SAMPLE POS',
    this.closedBy,
  });

  Future<List<int>> buildReceiptBytes() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final bytes = <int>[];

    String rangeLabel() {
      if (from == null || to == null) return 'Today';
      final fromStr = DateFormat('yyyy-MM-dd HH:mm').format(from!);
      final toStr = DateFormat('yyyy-MM-dd HH:mm').format(to!);
      return '$fromStr to $toStr';
    }

    bytes.addAll(
      generator.text(
        storeName,
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
        'Z REPORT',
        styles: const PosStyles(align: PosAlign.center, bold: true),
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
        'Range: ${rangeLabel()}',
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    if (closedBy != null && closedBy!.trim().isNotEmpty) {
      bytes.addAll(
        generator.text(
          'Closed By: ${closedBy!.trim()}',
          styles: const PosStyles(align: PosAlign.center),
        ),
      );
    }
    bytes.addAll(generator.hr(ch: '-'));

    bytes.addAll(
      generator.row([
        PosColumn(text: 'Total Sales', width: 8, styles: const PosStyles(bold: true)),
        PosColumn(
          text: Helper.formatReceiptCurrency(totalSales),
          width: 4,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]),
    );
    bytes.addAll(
      generator.row([
        PosColumn(text: 'Transactions', width: 8),
        PosColumn(
          text: txCount.toStringAsFixed(0),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]),
    );
    bytes.addAll(
      generator.row([
        PosColumn(text: 'Items Sold', width: 8),
        PosColumn(
          text: totalQty.toStringAsFixed(0),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]),
    );
    bytes.addAll(
      generator.row([
        PosColumn(text: 'Total Payment', width: 8),
        PosColumn(
          text: Helper.formatReceiptCurrency(totalPayment),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]),
    );
    bytes.addAll(
      generator.row([
        PosColumn(text: 'Avg Ticket', width: 8),
        PosColumn(
          text: Helper.formatReceiptCurrency(avgTicket),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]),
    );

    bytes.addAll(generator.hr(ch: '-'));
    bytes.addAll(
      generator.text(
        '*** END OF DAY CLOSED ***',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
    );
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    return bytes;
  }
}
