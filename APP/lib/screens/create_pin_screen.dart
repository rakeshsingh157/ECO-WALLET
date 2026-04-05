/// ECO Wallet — Mandatory PIN Creation Screen
/// Shown after successful registration. User must create a 6-digit PIN before
/// they can access the main app.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import 'main_shell.dart';

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirmStep = false;
  bool _isLoading = false;
  String? _error;

  void _onKeyTap(String key) {
    if (_isLoading) return;

    setState(() => _error = null);

    if (!_isConfirmStep) {
      // Creating PIN
      if (key == '⌫') {
        if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
      } else if (_pin.length < 6) {
        setState(() => _pin += key);
        if (_pin.length == 6) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) setState(() => _isConfirmStep = true);
          });
        }
      }
    } else {
      // Confirming PIN
      if (key == '⌫') {
        if (_confirmPin.isNotEmpty) setState(() => _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1));
      } else if (_confirmPin.length < 6) {
        setState(() => _confirmPin += key);
        if (_confirmPin.length == 6) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _submitPin();
          });
        }
      }
    }
  }

  Future<void> _submitPin() async {
    if (_pin != _confirmPin) {
      setState(() {
        _error = 'PINs do not match. Please try again.';
        _confirmPin = '';
        _isConfirmStep = false;
        _pin = '';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.setPin(_pin);
      if (res['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('require_pin', true);

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => MainShell(),
              transitionDuration: const Duration(milliseconds: 500),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
            ),
            (route) => false,
          );
        }
      } else {
        setState(() {
          _error = res['message'] ?? 'Failed to set PIN. Please try again.';
          _confirmPin = '';
          _isConfirmStep = false;
          _pin = '';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error. Please try again.';
        _confirmPin = '';
        _isConfirmStep = false;
        _pin = '';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPin = _isConfirmStep ? _confirmPin : _pin;
    final screenHeight = MediaQuery.of(context).size.height;
    // Scale numpad key size for smaller screens
    final keySize = screenHeight < 700 ? 56.0 : 72.0;
    final keyFont = screenHeight < 700 ? 22.0 : 28.0;
    final keyPadding = screenHeight < 700 ? 4.0 : 6.0;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        SizedBox(height: screenHeight < 700 ? 24 : 48),

                        // Lock icon
                        Container(
                          width: screenHeight < 700 ? 60 : 80,
                          height: screenHeight < 700 ? 60 : 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [EcoColors.primaryContainer, EcoColors.onPrimaryContainer],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: EcoColors.primaryContainer.withOpacity(0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(Icons.lock_outline, size: screenHeight < 700 ? 28 : 36, color: EcoColors.surface),
                        ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8)),

                        SizedBox(height: screenHeight < 700 ? 20 : 32),

                        // Title
                        Text(
                          _isConfirmStep ? 'Confirm Your PIN' : 'Create Security PIN',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: screenHeight < 700 ? 20 : 24,
                            fontWeight: FontWeight.w700,
                            color: EcoColors.primary,
                          ),
                        ).animate().fadeIn(duration: 400.ms),

                        const SizedBox(height: 8),

                        Text(
                          _isConfirmStep
                              ? 'Re-enter your 6-digit PIN to confirm'
                              : 'Set a 6-digit PIN to secure your transactions',
                          style: GoogleFonts.inter(fontSize: 14, color: EcoColors.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: screenHeight < 700 ? 24 : 40),

                        // PIN dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (index) {
                            final isFilled = index < currentPin.length;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: isFilled ? 18 : 14,
                              height: isFilled ? 18 : 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isFilled ? EcoColors.primaryContainer : Colors.transparent,
                                border: Border.all(
                                  color: isFilled
                                      ? EcoColors.primaryContainer
                                      : EcoColors.onSurfaceVariant.withOpacity(0.3),
                                  width: 2,
                                ),
                                boxShadow: isFilled
                                    ? [
                                        BoxShadow(
                                          color: EcoColors.primaryContainer.withOpacity(0.4),
                                          blurRadius: 8,
                                        )
                                      ]
                                    : null,
                              ),
                            );
                          }),
                        ),

                        // Error message
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: EcoColors.errorContainer.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, color: EcoColors.error, size: 16),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _error!,
                                    style: GoogleFonts.inter(fontSize: 13, color: EcoColors.error),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().shake(duration: 400.ms),
                        ],

                        if (_isLoading) ...[
                          const SizedBox(height: 16),
                          const CircularProgressIndicator(
                            color: EcoColors.primaryContainer,
                            strokeWidth: 2,
                          ),
                        ],

                        const Spacer(),

                        // Numpad
                        _buildNumpad(keySize, keyFont, keyPadding),

                        SizedBox(height: screenHeight < 700 ? 16 : 32),

                        // Security badge
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shield, size: 14, color: EcoColors.onSurfaceVariant.withOpacity(0.4)),
                              const SizedBox(width: 8),
                              Text(
                                'YOUR PIN IS ENCRYPTED & NEVER STORED IN PLAIN TEXT',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                  color: EcoColors.onSurfaceVariant.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: screenHeight < 700 ? 12 : 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNumpad(double keySize, double keyFont, double keyPadding) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: keys.map((row) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: keyPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((k) {
              if (k.isEmpty) return SizedBox(width: keySize, height: keySize);
              return GestureDetector(
                onTap: () => _onKeyTap(k),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: keySize,
                  height: keySize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: EcoColors.surfaceContainerLow,
                  ),
                  child: k == '⌫'
                      ? Icon(Icons.backspace_outlined, color: EcoColors.onSurfaceVariant, size: keyFont * 0.75)
                      : Text(
                          k,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: keyFont,
                            fontWeight: FontWeight.w600,
                            color: EcoColors.onSurface,
                          ),
                        ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
