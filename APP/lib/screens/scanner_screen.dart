import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme.dart';
import 'send_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController? _controller;
  bool _scanned = false;
  final ValueNotifier<TorchState> _torchState = ValueNotifier(TorchState.off);

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final rawValue = barcode!.rawValue!.trim();
    if (rawValue.isEmpty) return;

    setState(() => _scanned = true);
    _controller?.stop();

    String? targetUserId;
    String? amountStr;
    String? recipientName;
    String? paymentId;

    try {
      final payload = jsonDecode(rawValue);
      if (payload is Map<String, dynamic>) {
        targetUserId = payload['user_id']?.toString() ?? payload['merchant_id']?.toString() ?? payload['merchant']?.toString();
        amountStr = payload['amount']?.toString();
        recipientName = payload['name']?.toString() ?? payload['business_name']?.toString() ?? payload['merchant_name']?.toString() ?? payload['shop_name']?.toString();
        paymentId = payload['payment_id']?.toString() ?? payload['paymentId']?.toString();
      }
    } catch (_) {}

    if (targetUserId == null && (rawValue.contains('://') || rawValue.contains('pay?'))) {
      try {
        final uri = Uri.parse(rawValue);
        targetUserId = uri.queryParameters['merchant'] ?? uri.queryParameters['user_id'] ?? uri.queryParameters['pa'];
        amountStr = uri.queryParameters['amount'] ?? uri.queryParameters['am'];
        recipientName = uri.queryParameters['name'] ?? uri.queryParameters['pn'] ?? uri.queryParameters['business_name'];
        paymentId = uri.queryParameters['payment_id'] ?? uri.queryParameters['pid'];
        
        if (targetUserId == null && uri.pathSegments.isNotEmpty) {
          final lastSeg = uri.pathSegments.last;
          if (lastSeg.isNotEmpty && lastSeg != 'pay') {
            targetUserId = lastSeg;
          }
        }
      } catch (_) {}
    }

    targetUserId ??= rawValue;

    if (targetUserId.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SendScreen(
            prefillReceiverId: targetUserId,
            prefillAmount: amountStr,
            prefillReceiverName: recipientName,
            prefillPaymentId: paymentId,
          ),
        ),
      );
      return;
    }

    // If invalid
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid QR code')),
    );
    setState(() => _scanned = false);
    _controller?.start();
  }

  Future<void> _pickGalleryImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      final capture = await _controller!.analyzeImage(xFile.path);
      if (capture != null) {
        _onDetect(capture);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No valid QR code found in the image.')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Camera preview
          if (_controller != null)
            MobileScanner(
              controller: _controller!,
              onDetect: _onDetect,
            ),

          // Overlay
          Container(
            color: EcoColors.surface.withOpacity(0.5),
          ),

          // Scanner frame
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: EcoColors.primaryContainer.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  ..._buildCorners(),
                ],
              ),
            ),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.qr_code_scanner, color: EcoColors.primaryContainer, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'ECO Wallet',
                        style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 3, color: EcoColors.primaryContainer),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _pickGalleryImage,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: EcoColors.surfaceContainerHighest,
                          ),
                          child: const Icon(Icons.image, size: 20, color: EcoColors.primaryContainer),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ValueListenableBuilder(
                        valueListenable: _torchState,
                        builder: (context, state, child) {
                          return GestureDetector(
                            onTap: () {
                              _controller?.toggleTorch();
                              _torchState.value = _torchState.value == TorchState.on ? TorchState.off : TorchState.on;
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: EcoColors.surfaceContainerHighest,
                              ),
                              child: Icon(
                                state == TorchState.on ? Icons.flash_on : Icons.flash_off,
                                size: 20,
                                color: state == TorchState.on ? Colors.amber : EcoColors.primaryContainer,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom text
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, EcoColors.surface.withOpacity(0.95)],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Ready to Scan',
                    style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w600, color: EcoColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Align QR code within the frame to automatically\ndetect the wallet address or transaction details.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 14, color: EcoColors.onSurfaceVariant, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EcoColors.surfaceContainerHighest,
                        foregroundColor: EcoColors.onSurface,
                      ),
                      child: Text('CLOSE SCANNER', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const size = 24.0;
    const color = EcoColors.primaryContainer;
    const width = 3.0;

    return [
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: width),
              left: BorderSide(color: color, width: width),
            ),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(12)),
          ),
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: width),
              right: BorderSide(color: color, width: width),
            ),
            borderRadius: BorderRadius.only(topRight: Radius.circular(12)),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: width),
              left: BorderSide(color: color, width: width),
            ),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12)),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: width),
              right: BorderSide(color: color, width: width),
            ),
            borderRadius: BorderRadius.only(bottomRight: Radius.circular(12)),
          ),
        ),
      ),
    ];
  }
}
