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

  void _scanStandeeQr() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SizedBox(
        height: 480,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SCAN PHYSICAL SHOP UPI QR',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      final rawValue = barcode.rawValue;
                      if (rawValue != null && rawValue.isNotEmpty) {
                        _parseAndApplyUpiQr(rawValue);
                        Navigator.pop(ctx);
                        break;
                      }
                    }
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Point camera at your PhonePe, Google Pay, or Paytm standee QR',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickQrFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
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
            content: const Text('No QR code detected in the selected image. Please select a clear QR photo or scan directly.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not read image: $e'),
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

  void _saveProfile() async {
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
      messenger.showSnackBar(
        SnackBar(
          content: Text(success ? 'Shop profile & UPI QR updated successfully!' : 'Failed to update profile'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
      Navigator.pop(context);
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
                    'STORE INFORMATION',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _shopNameCtrl,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: 'Store / Business Name *',
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
                      labelText: 'Registered Mobile Number',
                      prefixIcon: Icon(Icons.phone_rounded, color: AppColors.terracotta),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _gstinCtrl,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: 'GSTIN Number (Optional)',
                      prefixIcon: Icon(Icons.badge_rounded, color: AppColors.forestMint),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _addressCtrl,
                    maxLines: 2,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Store Address (On Receipts)',
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
                        'STORE UPI QR SETUP',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.info),
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _pickQrFromGallery,
                            icon: const Icon(Icons.photo_library_rounded, size: 14),
                            label: const Text('Gallery'),
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
                            label: const Text('Scan'),
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
                      labelText: 'Store UPI VPA / ID *',
                      hintText: 'e.g. yourname@okhdfcbank, 9876543210@paytm',
                      prefixIcon: Icon(Icons.account_balance_rounded, color: AppColors.info),
                      helperText: 'Customers will pay directly to this UPI ID on bills',
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
              child: ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('SAVE STORE PROFILE & QR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.terracotta,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
