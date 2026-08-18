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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.terracotta.withValues(alpha: 0.15),
                    AppColors.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.terracotta.withValues(alpha: 0.25), width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.terracotta,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.terracotta.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentShop,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _ownerNameCtrl.text.trim().isNotEmpty ? _ownerNameCtrl.text.trim() : 'Store Owner',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.forestMint.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.forestMint.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: AppColors.forestMint,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'LIVE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.forestMint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.terracotta.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.info_outline_rounded, size: 15, color: AppColors.terracotta),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('store_information').toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _shopNameCtrl,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: '${context.tr('store_name')} *',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.terracotta.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.store_rounded, color: AppColors.terracotta, size: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _ownerNameCtrl,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: '${context.tr('proprietor')} *',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.chaiGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.person_rounded, color: AppColors.chaiGold, size: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _mobileCtrl,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: context.tr('registered_mobile'),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.forestMint.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.phone_rounded, color: AppColors.forestMint, size: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _gstinCtrl,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: '${context.tr('gstin')} (${context.tr('optional')})',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.warmNavy.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.badge_rounded, color: AppColors.warmNavy, size: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _addressCtrl,
                    maxLines: 2,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      labelText: context.tr('store_address_receipt'),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.softIndigo.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.location_on_rounded, color: AppColors.softIndigo, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.35), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.info.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.qr_code_rounded, size: 15, color: AppColors.info),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('store_upi_qr_setup').toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickQrFromGallery,
                            icon: const Icon(Icons.photo_library_rounded, size: 13),
                            label: Text(context.tr('gallery')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.info.withValues(alpha: 0.15),
                              foregroundColor: AppColors.info,
                              elevation: 0,
                              side: BorderSide(color: AppColors.info.withValues(alpha: 0.4)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              visualDensity: VisualDensity.compact,
                              textStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _scanStandeeQr,
                            icon: const Icon(Icons.qr_code_scanner_rounded, size: 13),
                            label: Text(context.tr('scan')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.info,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              visualDensity: VisualDensity.compact,
                              textStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _upiIdCtrl,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
                    decoration: InputDecoration(
                      labelText: '${context.tr('store_upi_id')} *',
                      hintText: 'e.g. yourname@okhdfcbank, 9876543210@paytm',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.account_balance_rounded, color: AppColors.info, size: 20),
                        ),
                      ),
                      helperText: context.tr('store_upi_sub'),
                      helperStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 18),

                  if (previewUpiUri.isNotEmpty) ...[
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: QrImageView(
                                data: previewUpiUri,
                                version: QrVersions.auto,
                                size: 170.0,
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
                            const SizedBox(height: 12),
                            Text(
                              currentShop,
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.info.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                currentUpi,
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.info),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.qr_code_2_rounded, size: 44, color: AppColors.info),
                          const SizedBox(height: 10),
                          Text(
                            context.tr('upload_qr_hint'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _pickQrFromGallery,
                                  icon: const Icon(Icons.photo_library_rounded, size: 15),
                                  label: Text(context.tr('pick_gallery'), overflow: TextOverflow.ellipsis),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.info,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _scanStandeeQr,
                                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 15),
                                  label: Text(context.tr('scan_standee'), overflow: TextOverflow.ellipsis),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: AppColors.info, width: 1.5),
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

            Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.terracotta.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.terracotta,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.save_rounded, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            context.tr('save_shop_profile_qr').toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
