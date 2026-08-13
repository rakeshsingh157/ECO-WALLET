import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import 'main_shell.dart';
import 'server_config_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileCtrl = TextEditingController(text: '9876543210');
  final _pinCtrl = TextEditingController();
  final _newPinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();
  final _shopNameCtrl = TextEditingController(text: 'Sharma Kirana Store');
  final _ownerNameCtrl = TextEditingController(text: 'Mr. Sharma');

  bool _wantSetPin = false;
  bool _obscurePin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _pinCtrl.dispose();
    _newPinCtrl.dispose();
    _confirmPinCtrl.dispose();
    _shopNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final phone = _mobileCtrl.text.trim();

    // 1. Check if PIN was previously set
    if (auth.hasPinSet) {
      if (!auth.verifyPin(_pinCtrl.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect Security PIN! Access Denied.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    // 2. Validate new PIN if setting option selected
    String finalPin = auth.securityPin;
    if (!auth.hasPinSet && _wantSetPin) {
      if (_newPinCtrl.text.length != 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Security PIN must be 4 digits'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (_newPinCtrl.text != _confirmPinCtrl.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PINs do not match!'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      finalPin = _newPinCtrl.text;
    }

    setState(() => _isLoading = true);

    // Auto-generate Merchant ID and API Key from phone number
    final autoMerchantId = 'mch_$phone';
    final autoApiKey = 'key_mch_${phone}_auto';

    await auth.saveCredentials(
      apiKey: autoApiKey,
      webhookSecret: 'whsec_auto_$phone',
      merchantId: autoMerchantId,
      shopName: _shopNameCtrl.text.trim(),
      ownerName: _ownerNameCtrl.text.trim(),
      mobileNumber: phone,
      securityPin: finalPin,
      baseUrl: auth.baseUrl.isNotEmpty ? auth.baseUrl : AppConstants.defaultEcoWalletBaseUrl,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome, ${auth.ownerName}! Auto-Merchant Account Ready.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFF8C75),
                Color(0xFFE8446D),
                AppColors.darkNavy,
              ],
              stops: [0.0, 0.3, 0.7],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // App Branding Header
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.darkNavy,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.warmPeach, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'assets/images/shopkeeper.png',
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(Icons.storefront_rounded, color: AppColors.warmCoral),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dukaan Dost',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Smart POS & Auto ECO Payment',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Boxie Mascot Banner
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 20,
                    color: AppColors.darkNavy.withValues(alpha: 0.85),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/boxie.png',
                          width: 54,
                          height: 54,
                          errorBuilder: (c, e, s) => const Icon(Icons.security_rounded, size: 36, color: AppColors.warmCoral),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            auth.hasPinSet
                                ? 'Enter Mobile & Security PIN to login.'
                                : 'Merchant account & QR payments are automatically generated!',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warmPeach,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Form Container Card
                  GlassCard(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(22),
                    color: AppColors.darkCard.withValues(alpha: 0.95),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Shopkeeper Setup',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.settings_input_component_rounded, color: AppColors.warmCoral),
                                tooltip: 'Server Config',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ServerConfigScreen()),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Mobile Number Field
                          TextFormField(
                            controller: _mobileCtrl,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            decoration: const InputDecoration(
                              labelText: 'Mobile Number *',
                              hintText: '10-digit Mobile',
                              prefixIcon: Icon(Icons.phone_rounded, color: AppColors.warmCoral),
                              counterText: '',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().length != 10) {
                                return 'Enter valid 10-digit mobile number';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 14),

                          // If PIN IS SET -> Show Enter PIN field
                          if (auth.hasPinSet) ...[
                            TextFormField(
                              controller: _pinCtrl,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              obscureText: _obscurePin,
                              decoration: InputDecoration(
                                labelText: 'Enter 4-Digit Security PIN *',
                                prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.warmCoral),
                                counterText: '',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePin ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    color: AppColors.textMuted,
                                  ),
                                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.length != 4) {
                                  return 'Enter 4-digit security PIN';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                          ],

                          // If PIN IS NOT SET -> Optional Set PIN Toggle & Fields
                          if (!auth.hasPinSet) ...[
                            SwitchListTile(
                              value: _wantSetPin,
                              onChanged: (val) => setState(() => _wantSetPin = val),
                              activeColor: AppColors.warmCoral,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Set Security PIN (Optional)',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                'Protect shop access with a 4-digit PIN',
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ),

                            if (_wantSetPin) ...[
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _newPinCtrl,
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                obscureText: _obscurePin,
                                decoration: const InputDecoration(
                                  labelText: 'Create 4-Digit PIN',
                                  prefixIcon: Icon(Icons.pin_rounded, color: AppColors.warmCoral),
                                  counterText: '',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _confirmPinCtrl,
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                obscureText: _obscurePin,
                                decoration: const InputDecoration(
                                  labelText: 'Confirm 4-Digit PIN',
                                  prefixIcon: Icon(Icons.check_circle_outline_rounded, color: AppColors.warmCoral),
                                  counterText: '',
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                          ],

                          // Shop & Owner Details
                          TextFormField(
                            controller: _shopNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Shop Name',
                              prefixIcon: Icon(Icons.store_rounded, color: AppColors.warmCoral),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Shop Name required' : null,
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: _ownerNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Owner Name',
                              prefixIcon: Icon(Icons.person_rounded, color: AppColors.warmCoral),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Owner Name required' : null,
                          ),
                          const SizedBox(height: 18),

                          // Auto-Generation Badge
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome_rounded, color: AppColors.success, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Merchant QR Account will be auto-created instantly.',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          GradientButton(
                            text: auth.hasPinSet ? 'Login with PIN' : 'Start Billing & QR App',
                            icon: Icons.arrow_forward_rounded,
                            isLoading: _isLoading,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
