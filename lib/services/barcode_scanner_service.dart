import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sales_management/components/barcode_scanner_screen.dart';
import 'package:sales_management/components/theme_helper.dart';
import 'package:sales_management/models/product.dart';

/// Service for phone camera barcode scanning across Product Management and POS.
class BarcodeScannerService {
  BarcodeScannerService._();

  /// Prompts camera permission if needed and opens the full-screen camera barcode scanner.
  /// Returns the detected barcode string, or null if cancelled.
  static Future<String?> scanBarcode(
    BuildContext context, {
    String title = 'Scan Barcode',
    String instruction = 'Align the barcode or QR code within the frame',
  }) async {
    // 1. Check & request camera permission
    final hasPermission = await _ensureCameraPermission(context);
    if (!hasPermission) return null;

    if (!context.mounted) return null;

    // 2. Open scanner screen
    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (ctx) => BarcodeScannerScreen(
          title: title,
          instruction: instruction,
        ),
      ),
    );

    return scannedCode?.trim();
  }

  /// Scans a barcode with the camera and queries the database for the matching product.
  /// Returns the product map if found, or null if not found/cancelled.
  static Future<Map<String, dynamic>?> scanAndLookupProduct(
    BuildContext context, {
    String title = 'Scan Product Barcode',
  }) async {
    final barcode = await scanBarcode(
      context,
      title: title,
      instruction: 'Scan a product barcode to view or edit details',
    );

    if (barcode == null || barcode.isEmpty) return null;

    // Query product by barcode
    final products = await Product().getProducts(barcode);
    final match = products.firstWhere(
      (p) => p['barcode']?.toString() == barcode,
      orElse: () => products.isNotEmpty ? products.first : <String, dynamic>{},
    );

    if (match.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No product found with barcode "$barcode"'),
            backgroundColor: ThemeHelper.warning(),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }

    return match;
  }

  /// Ensures camera permission is granted. If permanently denied, shows a dialog leading to app settings.
  static Future<bool> _ensureCameraPermission(BuildContext context) async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      if (!context.mounted) return false;
      final shouldOpenSettings = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Camera Permission Needed'),
          content: const Text(
            'Camera permission is required to scan barcodes. Please enable camera access in your device settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeHelper.primaryColor(),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      if (shouldOpenSettings == true) {
        await openAppSettings();
      }
      return false;
    }

    // Request permission
    final requested = await Permission.camera.request();
    if (!requested.isGranted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Camera permission was not granted.'),
          backgroundColor: ThemeHelper.error(),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return requested.isGranted;
  }
}
