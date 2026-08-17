import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/app_notifier.dart';
import '../../core/localization.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/mascot_badge.dart';
import '../main_shell.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  bool _obscurePin = true;
  bool _isLoading = false;
  int _selectedLoginType = 0;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    if (auth.mobileNumber.isNotEmpty) {
      _mobileCtrl.text = auth.mobileNumber;
    }
  }

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final mobile = _mobileCtrl.text.trim();
    final pin = _pinCtrl.text.trim();

    final bool success;
    if (_selectedLoginType == 0) {
      success = await auth.loginWithPin(mobile, pin);
    } else {
      success = await auth.loginStaff(phone: mobile, pin: pin);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        final welcomeMsg = _selectedLoginType == 1 && auth.staffName.isNotEmpty
            ? 'Logged in as ${auth.staffName} (${auth.staffRole})'
            : 'Welcome back to ${auth.shopName}!';

        AppNotifier.success(
          context,
          welcomeMsg,
          title: _selectedLoginType == 1 ? 'STAFF AUTHENTICATED' : 'STORE ACCESS GRANTED',
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      } else {
        AppNotifier.error(
          context,
          auth.authError ?? 'Login failed. Please check mobile/PIN.',
          title: 'LOGIN FAILED',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 10),
                MascotBadge(
                  assetPath: MascotAssets.shopkeeper,
                  size: 90,
                  speechBubbleText: _selectedLoginType == 0
                      ? 'Swagat hai! Apni dukaan me login karein'
                      : 'Namaste! Staff PIN se shop me billing shuru karein',
                ),
                const SizedBox(height: 16),

                Text(
                  'DUKAAN DOST',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _selectedLoginType == 0
                      ? 'Smart Retail POS & Khata Terminal'
                      : 'Cashier & Staff Billing Terminal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedLoginType = 0;
                              _pinCtrl.clear();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedLoginType == 0 ? AppColors.terracotta : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.store_rounded,
                                  size: 16,
                                  color: _selectedLoginType == 0 ? Colors.white : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  context.tr('owner').toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: _selectedLoginType == 0 ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedLoginType = 1;
                              _pinCtrl.clear();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedLoginType == 1 ? AppColors.forestMint : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.badge_rounded,
                                  size: 16,
                                  color: _selectedLoginType == 1 ? Colors.white : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  context.tr('staff').toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: _selectedLoginType == 1 ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                        controller: _mobileCtrl,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          labelText: _selectedLoginType == 0 ? 'Owner Mobile Number *' : 'Staff Mobile Number *',
                          hintText: '9876543210',
                          prefixIcon: Icon(
                            Icons.phone_rounded,
                            color: _selectedLoginType == 0 ? AppColors.terracotta : AppColors.forestMint,
                          ),
                        ),
                        validator: (v) => v == null || v.trim().length < 10 ? 'Enter valid 10-digit mobile number' : null,
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _pinCtrl,
                        obscureText: _obscurePin,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                        decoration: InputDecoration(
                          labelText: _selectedLoginType == 0 ? '4-digit Security PIN *' : '4-digit Staff PIN *',
                          hintText: '••••',
                          prefixIcon: Icon(
                            Icons.lock_rounded,
                            color: _selectedLoginType == 0 ? AppColors.terracotta : AppColors.forestMint,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePin ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () => setState(() => _obscurePin = !_obscurePin),
                          ),
                        ),
                        validator: (v) => v == null || v.trim().length < 4 ? 'Enter 4-digit PIN' : null,
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleLogin,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.login_rounded, size: 18),
                          label: Text(
                            _isLoading
                                ? '...'
                                : context.tr('login').toUpperCase(),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedLoginType == 0 ? AppColors.terracotta : AppColors.forestMint,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                if (_selectedLoginType == 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${context.tr('dont_have_account')} ',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SignupScreen()),
                          );
                        },
                        child: Text(
                          context.tr('register_now'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.terracotta,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Ask your store owner to add your mobile number and 4-digit PIN from Settings > Staff & Cashiers.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
