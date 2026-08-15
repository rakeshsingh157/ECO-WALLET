import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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
          content: Text(success ? 'Shop profile updated successfully!' : 'Failed to update profile'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
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
                children: [
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
                    controller: _upiIdCtrl,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: 'Store UPI VPA / ID (e.g. yourname@upi)',
                      prefixIcon: Icon(Icons.qr_code_rounded, color: AppColors.info),
                      helperText: 'Used to generate dynamic UPI QR with exact bill amount',
                      helperStyle: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _gstinCtrl,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: 'GSTIN Number',
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

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('SAVE STORE PROFILE'),
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
