/// ECO Wallet — Auth Screen (Login / Signup)
/// Matches the "Digital Ether" login UI mockup.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import 'main_shell.dart';
import 'create_pin_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    bool success;

    if (_isLogin) {
      success = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    } else {
      success = await auth.register(
        _nameCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
        referralCode: _referralCtrl.text.trim(),
      );
    }

    if (success && mounted) {
      final hasPin = auth.user?['has_pin'] == true;
      // New accounts always go to PIN creation; existing accounts check if PIN exists
      final destination = (!_isLogin || !hasPin) ? const CreatePinScreen() : MainShell();
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => destination,
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 48),

                    // Logo
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: EcoColors.surfaceContainerHighest,
                          border: Border.all(
                            color: EcoColors.primaryContainer.withOpacity(0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.eco,
                          size: 36,
                          color: EcoColors.primaryContainer,
                        ),
                      ),
                    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8)),

                    const SizedBox(height: 24),

                    // Title
                    Center(
                      child: Text(
                        'ECO Wallet',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: EcoColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Enter the Digital Ether of Finance',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: EcoColors.onSurfaceVariant,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Divider
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            EcoColors.outlineVariant.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Welcome text
                    Text(
                      _isLogin ? 'Welcome back' : 'Create account',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: EcoColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLogin
                          ? 'Please enter your details to access your vault.'
                          : 'Join the ECO ecosystem today.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: EcoColors.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Name field (signup only)
                    if (!_isLogin) ...[
                      _buildLabel('FULL NAME'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameCtrl,
                        style: GoogleFonts.inter(color: EcoColors.onSurface),
                        decoration: InputDecoration(
                          hintText: 'e.g. Rakesh Singh',
                          prefixIcon: Icon(Icons.person_outline, color: EcoColors.onSurfaceVariant.withOpacity(0.5)),
                        ),
                        validator: (v) => (v == null || v.trim().length < 2) ? 'Name required' : null,
                      ),
                      const SizedBox(height: 20),
                    ],

                    _buildLabel(_isLogin ? 'MOBILE NUMBER OR EMAIL' : 'EMAIL ADDRESS'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.inter(color: EcoColors.onSurface),
                      decoration: InputDecoration(
                        hintText: _isLogin ? 'e.g. 9876543210 or user@example.com' : 'e.g. name@example.com',
                        prefixIcon: Icon(_isLogin ? Icons.person_outline : Icons.alternate_email, color: EcoColors.onSurfaceVariant.withOpacity(0.5)),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter mobile number or email';
                        if (!_isLogin && !v.contains('@')) return 'Valid email required';
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    _buildLabel(_isLogin ? 'PASSWORD OR SECURITY PIN' : 'PASSWORD'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      style: GoogleFonts.inter(color: EcoColors.onSurface),
                      decoration: InputDecoration(
                        hintText: _isLogin ? 'Enter password or PIN' : '••••••••',
                        prefixIcon: Icon(Icons.lock_outline, color: EcoColors.onSurfaceVariant.withOpacity(0.5)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                            color: EcoColors.onSurfaceVariant.withOpacity(0.5),
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter password or PIN';
                        if (!_isLogin && v.length < 8) return 'Minimum 8 characters';
                        return null;
                      },
                    ),

                    if (!_isLogin) ...[
                      const SizedBox(height: 20),
                      _buildLabel('REFERRAL CODE (OPTIONAL)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _referralCtrl,
                        style: GoogleFonts.inter(color: EcoColors.onSurface),
                        decoration: InputDecoration(
                          hintText: 'e.g. ECO7X9K2P',
                          prefixIcon: Icon(Icons.group_add, color: EcoColors.onSurfaceVariant.withOpacity(0.5)),
                        ),
                      ),
                    ],

                    // Error message
                    if (auth.error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: EcoColors.errorContainer.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: EcoColors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                auth.error!,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: EcoColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(48),
                          gradient: const LinearGradient(
                            colors: [EcoColors.primaryContainer, EcoColors.primaryFixedDim],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: EcoColors.primaryContainer.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(48),
                            ),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: EcoColors.surface,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _isLogin ? 'Login' : 'Create Account',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: EcoColors.surface,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, color: EcoColors.surface, size: 20),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Toggle login/signup
                    Center(
                      child: Column(
                        children: [
                          Text(
                            _isLogin ? 'New to ECO Wallet?' : 'Already have an account?',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: EcoColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isLogin = !_isLogin;
                                auth.clearError();
                              });
                            },
                            child: Text(
                              _isLogin ? 'CREATE AN ACCOUNT' : 'SIGN IN',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3,
                                color: EcoColors.primaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Security badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildBadge(Icons.shield, 'AES-256'),
                        _buildBadge(Icons.security, 'ZERO-\nKNOWLEDGE'),
                        _buildBadge(Icons.fingerprint, 'BIOMETRIC'),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: EcoColors.onSurfaceVariant,
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 24, color: EcoColors.onSurfaceVariant.withOpacity(0.4)),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: EcoColors.onSurfaceVariant.withOpacity(0.4),
          ),
        ),
      ],
    );
  }
}
