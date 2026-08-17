import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/camera_scanner_modal.dart';

class ShopProfileScreen extends StatefulWidget {
  const ShopProfileScreen({super.key});

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen> {
  late TextEditingController _shopNameCtrl;
  late TextEditingController _ownerNameCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _gstinCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _upiIdCtrl;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _shopNameCtrl = TextEditingController(text: auth.shopName);
    _ownerNameCtrl = TextEditingController(text: auth.ownerName);
    _mobileCtrl = TextEditingController(text: auth.mobileNumber);
    _gstinCtrl = TextEditingController(text: auth.gstin);
    _addressCtrl = TextEditingController(text: auth.address);
    _upiIdCtrl = TextEditingController(text: auth.upiId);

    _upiIdCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _shopNameCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _mobileCtrl.dispose();
    _gstinCtrl.dispose();
    _addressCtrl.dispose();
    _upiIdCtrl.dispose();
    super.dispose();
  }

  void _scanStandeeQr() async {
    final scannedCode = await CameraScannerModal.show(
      context,
      title: 'SCAN PHYSICAL SHOP UPI QR',
      subtitle: 'Point camera at your PhonePe, Google Pay, or Paytm standee QR',
    );

    if (scannedCode != null && scannedCode.isNotEmpty && mounted) {
      _parseAndApplyUpiQr(scannedCode);
    }
  }

  Future<void> _pickQrFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (image == null) return;

      final controller = MobileScannerController();
      final BarcodeCapture? capture = await controller.analyzeImage(image.path);
      await controller.dispose();

      if (capture != null && capture.barcodes.isNotEmpty) {
        for (final barcode in capture.barcodes) {
          final rawValue = barcode.rawValue;
          if (rawValue != null && rawValue.isNotEmpty) {
            _parseAndApplyUpiQr(rawValue);
            return;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No QR code detected in this photo. Please try another image or use "Scan Standee QR".'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not process gallery image. Please use "Scan Standee QR" to scan directly.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _parseAndApplyUpiQr(String qrContent) {
    try {
      final uri = Uri.tryParse(qrContent);
      if (uri != null && uri.scheme == 'upi') {
        final pa = uri.queryParameters['pa'];
        final pn = uri.queryParameters['pn'];
        if (pa != null && pa.isNotEmpty) {
          setState(() {
            _upiIdCtrl.text = pa;
            if (pn != null && pn.isNotEmpty && _shopNameCtrl.text.isEmpty) {
              _shopNameCtrl.text = Uri.decodeComponent(pn);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Extracted UPI ID: $pa'),
              backgroundColor: AppColors.success,
            ),
          );
          return;
        }
      }

      if (qrContent.contains('@')) {
        setState(() {
          _upiIdCtrl.text = qrContent.trim();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Set UPI ID: ${qrContent.trim()}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (_) {}
  }

  bool _isSaving = false;

  void _saveProfile() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(
      shopName: _shopNameCtrl.text.trim(),
      ownerName: _ownerNameCtrl.text.trim(),
      mobileNumber: _mobileCtrl.text.trim(),
      gstin: _gstinCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      upiId: _upiIdCtrl.text.trim(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(success ? 'Shop profile & UPI QR updated successfully!' : 'Failed to update profile'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
      if (success) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final currentUpi = _upiIdCtrl.text.trim();
    final currentShop = _shopNameCtrl.text.trim().isNotEmpty ? _shopNameCtrl.text.trim() : 'Dukaan Dost';
    final previewUpiUri = currentUpi.isNotEmpty
        ? 'upi://pay?pa=${Uri.encodeComponent(currentUpi)}&pn=${Uri.encodeComponent(currentShop)}&cu=INR'
        : '';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          context.tr('shop_profile').toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('store_information'),
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _shopNameCtrl,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: '${context.tr('store_name')} *',
                      prefixIcon: Icon(Icons.store_rounded, color: AppColors.terracotta),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _ownerNameCtrl,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: '${context.tr('proprietor')} *',
                      prefixIcon: Icon(Icons.person_rounded, color: AppColors.terracotta),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _mobileCtrl,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: context.tr('registered_mobile'),
                      prefixIcon: Icon(Icons.phone_rounded, color: AppColors.terracotta),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _gstinCtrl,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: '${context.tr('gstin')} (${context.tr('optional')})',
                      prefixIcon: Icon(Icons.badge_rounded, color: AppColors.forestMint),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _addressCtrl,
                    maxLines: 2,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: context.tr('store_address_receipt'),
                      prefixIcon: Icon(Icons.location_on_rounded, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.info.withAlpha(90), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('store_upi_qr_setup'),
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.info),
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _pickQrFromGallery,
                            icon: const Icon(Icons.photo_library_rounded, size: 14),
                            label: Text(context.tr('gallery')),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.info),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          const SizedBox(width: 6),
                          OutlinedButton.icon(
                            onPressed: _scanStandeeQr,
                            icon: const Icon(Icons.qr_code_scanner_rounded, size: 14),
                            label: Text(context.tr('scan')),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.info),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _upiIdCtrl,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
                    decoration: InputDecoration(
                      labelText: '${context.tr('store_upi_id')} *',
                      hintText: 'e.g. yourname@okhdfcbank, 9876543210@paytm',
                      prefixIcon: Icon(Icons.account_balance_rounded, color: AppColors.info),
                      helperText: context.tr('store_upi_sub'),
                      helperStyle: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (previewUpiUri.isNotEmpty) ...[
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(30),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: QrImageView(
                              data: previewUpiUri,
                              version: QrVersions.auto,
                              size: 160.0,
                              backgroundColor: Colors.white,
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Colors.black,
                              ),
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentShop,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                          Text(
                            currentUpi,
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.info),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.qr_code_2_rounded, size: 40, color: AppColors.textMuted),
                          const SizedBox(height: 8),
                          Text(
                            'Upload QR screenshot from Gallery, scan your physical standee, or type your UPI ID',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _pickQrFromGallery,
                                  icon: const Icon(Icons.photo_library_rounded, size: 14),
                                  label: const Text('Pick Gallery', overflow: TextOverflow.ellipsis),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.info,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _scanStandeeQr,
                                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 14),
                                  label: const Text('Scan Standee', overflow: TextOverflow.ellipsis),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: AppColors.info),
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.terracotta,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.save_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('SAVE STORE PROFILE & QR'),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
