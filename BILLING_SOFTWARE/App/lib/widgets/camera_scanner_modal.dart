import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/localization.dart';
import '../core/theme.dart';

class CameraScannerModal extends StatefulWidget {
  final String title;
  final String subtitle;
  final Function(String code) onScanned;
  final bool continuous;

  const CameraScannerModal({
    super.key,
    required this.title,
    this.subtitle = 'Align target code inside the center frame',
    required this.onScanned,
    this.continuous = false,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    String subtitle = 'Align target code inside the center frame',
  }) async {
    String? scannedResult;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => CameraScannerModal(
        title: title,
        subtitle: subtitle,
        continuous: false,
        onScanned: (code) {
          scannedResult = code;
          Navigator.pop(sheetCtx);
        },
      ),
    );
    return scannedResult;
  }

  @override
  State<CameraScannerModal> createState() => _CameraScannerModalState();
}

class _CameraScannerModalState extends State<CameraScannerModal> with SingleTickerProviderStateMixin {
  late MobileScannerController _controller;
  late AnimationController _animController;
  bool _torchOn = false;

  final double _boxWidth = 260;
  final double _boxHeight = 150;

  String? _lastCandidate;
  int _candidateHits = 0;
  DateTime _lastHitTime = DateTime.now();
  bool _hasDispatched = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.unrestricted,
      facing: CameraFacing.back,
      torchEnabled: false,
      autoStart: true,
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.qrCode,
      ],
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_hasDispatched && !widget.continuous) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final clean = raw.trim();
      if (clean.isEmpty) continue;

      final isQr = barcode.format == BarcodeFormat.qrCode || clean.length > 20;

      if (isQr) {
        _dispatchValidCode(clean);
        break;
      }

      final now = DateTime.now();
      if (_lastCandidate == clean && now.difference(_lastHitTime).inMilliseconds < 400) {
        _candidateHits++;
        if (_candidateHits >= 2) {
          _dispatchValidCode(clean);
          break;
        }
      } else {
        _lastCandidate = clean;
        _candidateHits = 1;
        _lastHitTime = now;
      }
    }
  }

  void _dispatchValidCode(String code) {
    if (_hasDispatched && !widget.continuous) return;
    _hasDispatched = true;

    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    widget.onScanned(code);

    if (widget.continuous) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _hasDispatched = false;
            _lastCandidate = null;
            _candidateHits = 0;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.82;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        color: _torchOn ? AppColors.chaiGold : Colors.white,
                      ),
                      onPressed: () {
                        _controller.toggleTorch();
                        setState(() => _torchOn = !_torchOn);
                      },
                      tooltip: 'Toggle Flashlight',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.center_focus_strong_rounded, size: 16, color: AppColors.terracotta),
                const SizedBox(width: 6),
                Text(
                  'Ultra-Precision Optical Engine (EAN/UPC/Code128/QR)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final scanWindow = Rect.fromCenter(
                  center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
                  width: _boxWidth,
                  height: _boxHeight,
                );

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _controller,
                      scanWindow: scanWindow,
                      errorBuilder: (context, error, child) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt_outlined, size: 54, color: AppColors.terracotta),
                                const SizedBox(height: 16),
                                Text(
                                  'Camera Access Required',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  context.tr('enable_camera_permission'),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _controller.start();
                                  },
                                  icon: const Icon(Icons.refresh_rounded, size: 18),
                                  label: Text(context.tr('retry_camera')),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.terracotta,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      onDetect: _handleDetection,
                    ),

                    CustomPaint(
                      painter: ScannerOverlayPainter(scanWindow: scanWindow),
                    ),

                    Center(
                      child: Container(
                        width: _boxWidth,
                        height: _boxHeight,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.terracotta, width: 2.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            AnimatedBuilder(
                              animation: _animController,
                              builder: (context, child) {
                                return Positioned(
                                  top: _animController.value * (_boxHeight - 10),
                                  left: 10,
                                  right: 10,
                                  child: Container(
                                    height: 2.5,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.terracotta.withAlpha(25),
                                          AppColors.terracotta,
                                          AppColors.chaiGold,
                                          AppColors.terracotta,
                                          AppColors.terracotta.withAlpha(25),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.terracotta.withAlpha(150),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final double borderRadius;

  ScannerOverlayPainter({required this.scanWindow, this.borderRadius = 16.0});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.black.withAlpha(160);
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(scanWindow, Radius.circular(borderRadius)));

    final finalPath = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);
    canvas.drawPath(finalPath, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant ScannerOverlayPainter oldDelegate) =>
      oldDelegate.scanWindow != scanWindow;
}
