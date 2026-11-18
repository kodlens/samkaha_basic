import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sales_management/components/theme_helper.dart';

/// Full-screen camera barcode scanner screen with animated viewfinder,
/// torch toggle, camera switcher, and manual entry fallback.
class BarcodeScannerScreen extends StatefulWidget {
  final String title;
  final String instruction;

  const BarcodeScannerScreen({
    super.key,
    this.title = 'Scan Barcode',
    this.instruction = 'Align the barcode or QR code within the frame',
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _controller;
  late final AnimationController _animController;
  late final Animation<double> _animPosition;

  bool _isScanned = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _animPosition = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue?.trim();
      if (code != null && code.isNotEmpty) {
        setState(() => _isScanned = true);
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(code);
        break;
      }
    }
  }

  Future<void> _showManualInputDialog() async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter Barcode Manually'),
        content: TextField(
          controller: textController,
          autofocus: true,
          keyboardType: TextInputType.text,
          decoration: ThemeHelper.inputDecoration(
            'Barcode / SKU',
            hint: 'e.g. 123456789012',
            prefixIcon: const Icon(Icons.barcode_reader),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeHelper.primaryColor(),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                Navigator.of(ctx).pop(text);
              }
            },
            child: const Text('Use Code'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = ThemeHelper.primaryColor();
    final screenSize = MediaQuery.of(context).size;
    final scanBoxSize = (screenSize.shortestSide * 0.72).clamp(220.0, 320.0);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          // Torch toggle
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, child) {
              final isTorchOn = state.torchState == TorchState.on;
              return IconButton(
                icon: Icon(
                  isTorchOn ? Icons.flash_on : Icons.flash_off,
                  color: isTorchOn ? Colors.amber : Colors.white70,
                ),
                tooltip: isTorchOn ? 'Turn Off Flash' : 'Turn On Flash',
                onPressed: () => _controller.toggleTorch(),
              );
            },
          ),
          // Camera switch
          IconButton(
            icon: const Icon(Icons.cameraswitch_outlined, color: Colors.white70),
            tooltip: 'Flip Camera',
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera scanner
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.videocam_off_outlined,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Camera Unavailable',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.errorDetails?.message ??
                            'Please grant camera permissions in settings or type the barcode manually.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _showManualInputDialog,
                        icon: const Icon(Icons.keyboard_outlined, size: 18),
                        label: const Text('Enter Barcode Manually'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Custom Viewfinder Overlay
          CustomPaint(
            painter: _ScannerOverlayPainter(
              scanBoxSize: scanBoxSize,
              borderColor: ThemeHelper.primaryMatch(),
            ),
          ),

          // Animated Scanning Laser Beam
          Center(
            child: SizedBox(
              width: scanBoxSize - 16,
              height: scanBoxSize - 16,
              child: AnimatedBuilder(
                animation: _animPosition,
                builder: (context, child) {
                  return Align(
                    alignment: Alignment(0, (_animPosition.value * 2) - 1),
                    child: Container(
                      height: 2.5,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            ThemeHelper.primaryMatch(),
                            Colors.white,
                            ThemeHelper.primaryMatch(),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ThemeHelper.primaryMatch().withValues(alpha: 0.8),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Instruction and Bottom controls
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: ThemeHelper.primaryMatch(),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.instruction,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.black45,
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _showManualInputDialog,
                      icon: const Icon(Icons.keyboard_outlined, size: 18),
                      label: const Text(
                        'Type Manually',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws the dimmed background with a transparent rounded cutout and corner brackets
class _ScannerOverlayPainter extends CustomPainter {
  final double scanBoxSize;
  final Color borderColor;

  _ScannerOverlayPainter({
    required this.scanBoxSize,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanBoxSize,
      height: scanBoxSize,
    );

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, bgPaint);

    // Corner guides
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const cornerLen = 24.0;
    final l = rect.left;
    final r = rect.right;
    final t = rect.top;
    final b = rect.bottom;

    // Top-Left
    canvas.drawLine(Offset(l, t + cornerLen), Offset(l, t + 12), cornerPaint);
    canvas.drawLine(Offset(l + 12, t), Offset(l + cornerLen, t), cornerPaint);

    // Top-Right
    canvas.drawLine(Offset(r - cornerLen, t), Offset(r - 12, t), cornerPaint);
    canvas.drawLine(Offset(r, t + 12), Offset(r, t + cornerLen), cornerPaint);

    // Bottom-Left
    canvas.drawLine(Offset(l, b - cornerLen), Offset(l, b - 12), cornerPaint);
    canvas.drawLine(Offset(l + 12, b), Offset(l + cornerLen, b), cornerPaint);

    // Bottom-Right
    canvas.drawLine(Offset(r - cornerLen, b), Offset(r - 12, b), cornerPaint);
    canvas.drawLine(Offset(r, b - 12), Offset(r, b - cornerLen), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanBoxSize != scanBoxSize ||
        oldDelegate.borderColor != borderColor;
  }
}
