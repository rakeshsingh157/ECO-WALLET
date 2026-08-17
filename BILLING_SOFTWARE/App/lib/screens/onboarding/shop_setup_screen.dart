import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../widgets/language_picker_button.dart';
import '../../providers/auth_provider.dart';
import '../main_shell.dart';

class ShopSetupScreen extends StatefulWidget {
  const ShopSetupScreen({super.key});

  @override
  State<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends State<ShopSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameCtrl = TextEditingController(text: 'Ramesh Kirana Store');
  final _ownerNameCtrl = TextEditingController(text: 'Ramesh Sharma');
  final _gstinCtrl = TextEditingController();
  final _addressCtrl = TextEditingController(text: 'Main Market, City Center');

  String _businessCategory = 'Kirana & Grocery';
  final List<String> _categories = [
    'Kirana & Grocery',
    'Clothing & Footwear',
    'Electronics & Mobile',
    'Pharmacy & Medical',
    'Bakery & Cafe',
    'Hardware & Sanitary',
    'General Retail',
  ];

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _gstinCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _finishSetup() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    await auth.saveCredentials(
      apiKey: auth.apiKey.isNotEmpty ? auth.apiKey : 'merchant_live_demo_123',
      webhookSecret: auth.webhookSecret.isNotEmpty ? auth.webhookSecret : 'whsec_demo',
      merchantId: auth.merchantId.isNotEmpty ? auth.merchantId : 'mch_demo_123',
      shopName: _shopNameCtrl.text.trim(),
      ownerName: _ownerNameCtrl.text.trim(),
      mobileNumber: auth.mobileNumber.isNotEmpty ? auth.mobileNumber : '9876543210',
      securityPin: auth.securityPin.isNotEmpty ? auth.securityPin : '1234',
      baseUrl: auth.baseUrl,
    );

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'STORE SETUP',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: LanguagePickerButton(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configure your billing parameters and business profile for thermal tax invoices.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _shopNameCtrl,
                style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: 'Shop / Brand Name *',
                  prefixIcon: Icon(Icons.store_rounded, color: AppColors.terracotta),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter shop name' : null,
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _ownerNameCtrl,
                style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Proprietor / Owner Name *',
                  prefixIcon: Icon(Icons.person_rounded, color: AppColors.terracotta),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter owner name' : null,
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                initialValue: _businessCategory,
                decoration: InputDecoration(
                  labelText: 'Business Category',
                  prefixIcon: Icon(Icons.category_rounded, color: AppColors.terracotta),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary))))
                    .toList(),
                onChanged: (v) => setState(() => _businessCategory = v!),
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _gstinCtrl,
                style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: 'GSTIN (Optional)',
                  hintText: '29AAAAA0000A1Z5',
                  prefixIcon: Icon(Icons.badge_rounded, color: AppColors.forestMint),
                ),
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _addressCtrl,
                maxLines: 2,
                style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Store Address (Printed on Invoices) *',
                  prefixIcon: Icon(Icons.location_on_rounded, color: AppColors.textSecondary),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter store address' : null,
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _finishSetup,
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('COMPLETE SETUP & LAUNCH POS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
