import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
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
  late final TextEditingController _shopNameCtrl;
  late final TextEditingController _ownerNameCtrl;
  final _gstinCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

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
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _shopNameCtrl = TextEditingController(text: auth.shopName);
    _ownerNameCtrl = TextEditingController(text: auth.ownerName);
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _gstinCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  bool _isSaving = false;

  void _finishSetup() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    await auth.saveCredentials(
      apiKey: auth.apiKey.isNotEmpty ? auth.apiKey : '',
      webhookSecret: auth.webhookSecret.isNotEmpty ? auth.webhookSecret : '',
      merchantId: auth.merchantId.isNotEmpty ? auth.merchantId : '',
      shopName: _shopNameCtrl.text.trim(),
      ownerName: _ownerNameCtrl.text.trim(),
      mobileNumber: auth.mobileNumber.isNotEmpty ? auth.mobileNumber : '',
      securityPin: auth.securityPin.isNotEmpty ? auth.securityPin : '',
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
    final isDark = Theme.of(context).brightness == Brightness.dark || AppColors.isDark;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          context.tr('store_setup_title').toUpperCase(),
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
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('store_setup_desc'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2432) : const Color(0xFFF9F7F4),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2B3A4F) : const Color(0xFFE8E2D8),
                    width: 1.2,
                  ),
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
                          child: Icon(Icons.store_rounded, size: 16, color: AppColors.terracotta),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'STORE IDENTITY & BUSINESS',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'Store / Brand Name *',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _shopNameCtrl,
                      enabled: !_isSaving,
                      style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        hintText: context.tr('shop_name_hint'),
                        prefixIcon: Icon(Icons.storefront_rounded, color: AppColors.terracotta, size: 20),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? context.trRead('enter_shop_name') : null,
                    ),

                    const SizedBox(height: 14),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'Proprietor / Owner Name *',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _ownerNameCtrl,
                      enabled: !_isSaving,
                      style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        hintText: context.tr('owner_name_hint'),
                        prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.terracotta, size: 20),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? context.trRead('enter_owner_name') : null,
                    ),

                    const SizedBox(height: 14),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'Business Category',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _businessCategory,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.category_outlined, color: AppColors.terracotta, size: 20),
                      ),
                      items: _categories
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c, style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                              ))
                          .toList(),
                      onChanged: _isSaving ? null : (v) => setState(() => _businessCategory = v!),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2432) : const Color(0xFFF9F7F4),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2B3A4F) : const Color(0xFFE8E2D8),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.forestMint.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.forestMint),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'TAX & OFFICIAL STORE ADDRESS',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'GSTIN (Optional)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _gstinCtrl,
                      enabled: !_isSaving,
                      textCapitalization: TextCapitalization.characters,
                      style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        hintText: '29AAAAA0000A1Z5',
                        prefixIcon: Icon(Icons.badge_outlined, color: AppColors.forestMint, size: 20),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'Full Store Address (Printed on Invoices) *',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _addressCtrl,
                      enabled: !_isSaving,
                      maxLines: 2,
                      style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: context.tr('store_address_receipt'),
                        prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textSecondary, size: 20),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? context.trRead('enter_store_address') : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _finishSetup,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 20),
                  label: Text(
                    _isSaving ? 'CONFIGURING STORE...' : context.tr('complete_setup_launch').toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
