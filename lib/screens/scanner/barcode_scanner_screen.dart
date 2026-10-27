import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_theme.dart';

/// Full-featured camera barcode/QR scanner screen with clean overlay,
/// flash/camera toggle controls, and manual input fallback.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue?.trim();
      if (rawValue != null && rawValue.isNotEmpty) {
        setState(() => _isProcessing = true);
        Navigator.of(context).pop(rawValue);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.midnightNavy,
      appBar: AppBar(
        title: const Text('Scan Tracking Code'),
        backgroundColor: AppTheme.midnightNavy,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: AppTheme.electricLime),
            tooltip: 'Toggle Flash',
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_outlined, color: AppTheme.cloudWhite),
            tooltip: 'Flip Camera',
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera scanner view
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off_outlined,
                          size: 56, color: Color(0xFFF87171)),
                      const SizedBox(height: 16),
                      const Text(
                        'Camera Unavailable',
                        style: TextStyle(
                          color: AppTheme.cloudWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.errorDetails?.message ??
                            'Camera permission is required to scan shipping barcodes.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.keyboard_outlined, size: 18),
                        label: const Text('Enter Manually'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Custom Scanner Target Reticle
          Positioned.fill(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(),
            ),
          ),

          // Top instructions banner
          Positioned(
            top: 24,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.qr_code_scanner, color: AppTheme.electricLime, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Align barcode or QR code on shipping label within frame',
                      style: TextStyle(color: AppTheme.cloudWhite, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom manual input option
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Cancel / Enter Manually'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surface,
                  foregroundColor: AppTheme.cloudWhite,
                  side: const BorderSide(color: AppTheme.cardBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scanSize = size.width * 0.72;
    final left = (size.width - scanSize) / 2;
    final top = (size.height - scanSize) / 2;
    final scanRect = Rect.fromLTWH(left, top, scanSize, scanSize);

    // Dim background outside scan window
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Corner brackets
    final cornerPaint = Paint()
      ..color = AppTheme.electricLime
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 28.0;

    // Top-left
    canvas.drawLine(Offset(left, top + cornerLength), Offset(left, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), cornerPaint);

    // Top-right
    canvas.drawLine(Offset(left + scanSize - cornerLength, top), Offset(left + scanSize, top), cornerPaint);
    canvas.drawLine(Offset(left + scanSize, top), Offset(left + scanSize, top + cornerLength), cornerPaint);

    // Bottom-left
    canvas.drawLine(Offset(left, top + scanSize - cornerLength), Offset(left, top + scanSize), cornerPaint);
    canvas.drawLine(Offset(left, top + scanSize), Offset(left + cornerLength, top + scanSize), cornerPaint);

    // Bottom-right
    canvas.drawLine(Offset(left + scanSize - cornerLength, top + scanSize), Offset(left + scanSize, top + scanSize), cornerPaint);
    canvas.drawLine(Offset(left + scanSize, top + scanSize), Offset(left + scanSize, top + scanSize - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
