import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/bill_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/supplier_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/theme_provider.dart';
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

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _initAndLaunch();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initAndLaunch() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final billProvider = Provider.of<BillProvider>(context, listen: false);
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    await auth.ensureInitialized();

    final minSplashDuration = Future.delayed(const Duration(milliseconds: 1400));

    if (auth.isConfigured && auth.baseUrl.isNotEmpty) {
      unawaited(Future.wait([
        productProvider.fetchProducts(auth.baseUrl, auth.apiKey),
        billProvider.fetchBills(auth.apiService),
        customerProvider.fetchCustomers(auth.apiService),
        expenseProvider.fetchExpenses(auth.apiService),
        supplierProvider.fetchSuppliers(auth.apiService),
        notificationProvider.fetchNotifications(auth.apiService),
      ]));
    }

    await minSplashDuration;

    if (mounted) {
      _navigateToNext();
    }
  }

  void _navigateToNext() {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => auth.isConfigured ? const MainShell() : const OnboardingScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark || AppColors.isDark;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    Container(
                      width: 116,
                      height: 116,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDark ? const Color(0xFF293649) : const Color(0xFFE8E4DC),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.terracotta.withValues(alpha: isDark ? 0.22 : 0.14),
                            blurRadius: 36,
                            offset: const Offset(0, 14),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(Icons.storefront_rounded, size: 56, color: AppColors.terracotta),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    Text(
                      'DUKAAN DOST',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Smart Retail POS & Khata Terminal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),

                    const Spacer(flex: 3),

                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.terracotta),
                      ),
                    ),

                    const SizedBox(height: 44),
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
