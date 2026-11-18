import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/services/barcode_scanner_service.dart';

void main() {
  test('BarcodeScannerService compiles and exposes static scan methods', () {
    expect(BarcodeScannerService.scanBarcode, isNotNull);
    expect(BarcodeScannerService.scanAndLookupProduct, isNotNull);
  });
}
