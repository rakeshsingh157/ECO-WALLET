import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../providers/auth_provider.dart';
import '../main_shell.dart';

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
          content: const Text('PINs do not match. Please enter the same 4-digit PIN.'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Store registered successfully! Welcome to Dukaan Dost.'),
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
                  'Create your store account to start fast POS billing, managing inventory, and tracking Khata.',
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
                    children: [
                      TextFormField(
                        controller: _shopNameCtrl,
                        style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Shop / Business Name *',
                          hintText: 'e.g. Ramesh Kirana Store',
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
                          hintText: 'e.g. Ramesh Sharma',
                          prefixIcon: Icon(Icons.person_rounded, color: AppColors.terracotta),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter owner name' : null,
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _mobileCtrl,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Mobile Number *',
                          hintText: '9876543210',
                          prefixIcon: Icon(Icons.phone_rounded, color: AppColors.terracotta),
                        ),
                        validator: (v) => v == null || v.trim().length < 10 ? 'Enter valid mobile number' : null,
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _pinCtrl,
                              obscureText: _obscurePin,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                              decoration: InputDecoration(
                                labelText: '4-digit PIN *',
                                prefixIcon: Icon(Icons.lock_rounded, color: AppColors.terracotta),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePin ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                                ),
                              ),
                              validator: (v) => v == null || v.trim().length < 4 ? 'Min 4 digits' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _confirmPinCtrl,
                              obscureText: _obscurePin,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                              decoration: InputDecoration(
                                labelText: 'Confirm PIN *',
                                prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.terracotta),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Confirm PIN' : null,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
