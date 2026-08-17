import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/bill_provider.dart';
import '../providers/customer_provider.dart';
import 'main_shell.dart';
import 'onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  String _statusMessage = 'Connecting to Dukaan Dost Cloud...';
  bool _showSkipButton = false;
  Timer? _statusTimer;
  Timer? _skipTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _startServerWarmupAndSync();
  }

  void _startServerWarmupAndSync() async {
    _statusTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _statusMessage = 'Waking up cloud server (Render instances)...');
      }
    });

    _skipTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _statusMessage = 'Syncing store catalog & sales data...';
          _showSkipButton = true;
        });
      }
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final billProvider = Provider.of<BillProvider>(context, listen: false);
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);

    if (auth.isConfigured && auth.baseUrl.isNotEmpty) {
      try {
        await Future.wait([
          productProvider.fetchProducts(auth.baseUrl, auth.apiKey).timeout(const Duration(seconds: 25), onTimeout: () {}),
          billProvider.fetchBills(auth.apiService).timeout(const Duration(seconds: 25), onTimeout: () {}),
          customerProvider.fetchCustomers(auth.apiService).timeout(const Duration(seconds: 25), onTimeout: () {}),
        ]);
      } catch (_) {}
    } else {
      await Future.delayed(const Duration(milliseconds: 1500));
    }

    if (!mounted) return;
    _navigateToNext();
  }

  void _navigateToNext() {
    _statusTimer?.cancel();
    _skipTimer?.cancel();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => auth.isConfigured ? const MainShell() : const OnboardingScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _skipTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      MascotAssets.shopkeeper,
                      width: 110,
                      height: 110,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'DUKAAN DOST',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      'Smart Retail POS & Khata Terminal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.terracotta,
                      ),
                    ),
                    const SizedBox(height: 16),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _statusMessage,
                        key: ValueKey<String>(_statusMessage),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    if (_showSkipButton) ...[
                      const SizedBox(height: 24),
                      TextButton.icon(
                        onPressed: _navigateToNext,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('Continue to Dashboard'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.terracotta,
                          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
