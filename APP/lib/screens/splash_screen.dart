/// ECO Wallet — Splash Screen
/// Matches the UI mockup: deep obsidian bg, centered logo, loading bar, tagline.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'auth_screen.dart';
import 'main_shell.dart';
import 'create_pin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final loggedIn = await auth.checkAuth();

    if (!mounted) return;

    Widget destination;
    if (!loggedIn) {
      destination = const AuthScreen();
    } else if (auth.user?['has_pin'] != true) {
      // User is logged in but has no PIN — force PIN creation
      destination = const CreatePinScreen();
    } else {
      destination = MainShell();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mesh background gradients
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: EcoColors.surface,
                gradient: RadialGradient(
                  center: const Alignment(-0.5, -0.3),
                  radius: 1.2,
                  colors: [
                    EcoColors.onPrimaryContainer.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -80,
            bottom: MediaQuery.of(context).size.height * 0.25,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    EcoColors.surfaceTint.withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Centered content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo with glow
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ambient glow
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: EcoColors.primaryContainer.withOpacity(0.15),
                            blurRadius: 80,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    // Logo circle
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            EcoColors.primaryContainer,
                            EcoColors.onPrimaryContainer,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: EcoColors.surfaceTint.withOpacity(0.15),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.token,
                        size: 48,
                        color: EcoColors.surface,
                      ),
                    ),
                    // Orbital leaf
                    Positioned(
                      top: 5,
                      right: 10,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: EcoColors.surfaceContainerHighest,
                          border: Border.all(
                            color: EcoColors.primaryContainer.withOpacity(0.2),
                          ),
                        ),
                        child: Icon(
                          Icons.eco,
                          size: 14,
                          color: EcoColors.primaryContainer,
                        ),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      duration: 800.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 600.ms),

                const SizedBox(height: 48),

                // App name
                Text(
                  'ECO WALLET',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 12,
                    color: EcoColors.primary,
                  ),
                )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.3, curve: Curves.easeOut),

                const SizedBox(height: 16),

                // Tagline with lines
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 1,
                      color: EcoColors.outlineVariant.withOpacity(0.3),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'SMART DIGITAL ECONOMY',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 5,
                        color: EcoColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 32,
                      height: 1,
                      color: EcoColors.outlineVariant.withOpacity(0.3),
                    ),
                  ],
                ).animate(delay: 700.ms).fadeIn(duration: 500.ms),
              ],
            ),
          ),

          // Loading bar
          Positioned(
            bottom: 96,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 200,
                height: 2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  color: EcoColors.surfaceContainerHighest,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 2200),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: constraints.maxWidth * value,
                            height: 2,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(1),
                              gradient: LinearGradient(
                                colors: [
                                  EcoColors.primaryContainer.withOpacity(0.2),
                                  EcoColors.primaryContainer,
                                  EcoColors.primaryContainer.withOpacity(0.2),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: EcoColors.primaryContainer.withOpacity(0.5),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ).animate(delay: 1000.ms).fadeIn(duration: 400.ms),
          ),

          // Footer
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'SECURELY ENCRYPTED  •  BLOCKCHAIN NATIVE',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 3,
                  color: EcoColors.onSurfaceVariant.withOpacity(0.4),
                ),
              ),
            ).animate(delay: 1200.ms).fadeIn(duration: 500.ms),
          ),
        ],
      ),
    );
  }
}
