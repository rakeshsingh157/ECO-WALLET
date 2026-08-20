import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/bill_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/language_picker_button.dart';
import '../main_shell.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();

  bool _obscurePin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _mobileCtrl.dispose();
    _pinCtrl.dispose();
    _confirmPinCtrl.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pinCtrl.text.trim() != _confirmPinCtrl.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.trRead('pins_do_not_match')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.registerMerchant(
      shopName: _shopNameCtrl.text.trim(),
      ownerName: _ownerNameCtrl.text.trim(),
      mobile: _mobileCtrl.text.trim(),
      pin: _pinCtrl.text.trim(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        if (auth.baseUrl.isNotEmpty) {
          context.read<ProductProvider>().clear();
          context.read<BillProvider>().clear();
          context.read<CustomerProvider>().clear();
          context.read<ExpenseProvider>().clear();
          context.read<SupplierProvider>().clear();
          context.read<NotificationProvider>().clear();

          context.read<ProductProvider>().fetchProducts(auth.baseUrl, auth.apiKey);
          context.read<BillProvider>().fetchBills(auth.apiService);
          context.read<CustomerProvider>().fetchCustomers(auth.apiService);
          context.read<ExpenseProvider>().fetchExpenses(auth.apiService);
          context.read<SupplierProvider>().fetchSuppliers(auth.apiService);
          context.read<NotificationProvider>().fetchNotifications(auth.apiService);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('register_success')),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.authError ?? 'Registration failed. Try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          context.tr('register_now').toUpperCase(),
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
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('signup_desc'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '${context.tr('shop_business_name')} *',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _shopNameCtrl,
                        style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          hintText: context.tr('shop_name_hint'),
                          prefixIcon: Icon(Icons.storefront_rounded, color: AppColors.terracotta, size: 20),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter shop name' : null,
                      ),

                      const SizedBox(height: 14),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '${context.tr('proprietor')} *',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _ownerNameCtrl,
                        style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          hintText: context.tr('owner_name_hint'),
                          prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.terracotta, size: 20),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter owner name' : null,
                      ),

                      const SizedBox(height: 14),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '${context.tr('mobile_number_label')} *',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: _mobileCtrl,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          hintText: '10-digit mobile number',
                          prefixIcon: Icon(Icons.phone_outlined, color: AppColors.terracotta, size: 20),
                        ),
                        validator: (v) => v == null || v.trim().length < 10 ? 'Enter valid mobile number' : null,
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    '${context.tr('pin_label')} *',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                TextFormField(
                                  controller: _pinCtrl,
                                  obscureText: _obscurePin,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2.0,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '••••',
                                    prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.terracotta, size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePin ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                        color: AppColors.textSecondary,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => _obscurePin = !_obscurePin),
                                    ),
                                  ),
                                  validator: (v) => v == null || v.trim().length < 4 ? 'Min 4 digits' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    '${context.tr('confirm_pin_label')} *',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                TextFormField(
                                  controller: _confirmPinCtrl,
                                  obscureText: _obscurePin,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2.0,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '••••',
                                    prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.terracotta, size: 20),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Confirm PIN' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleSignup,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_circle_rounded, size: 18),
                          label: Text(_isLoading ? '...' : context.tr('register_now').toUpperCase()),
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
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${context.tr('already_have_account')} ',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: Text(
                        context.tr('sign_in'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.terracotta,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
