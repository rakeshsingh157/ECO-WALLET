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
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _initAndLoadAllData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initAndLoadAllData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final billProvider = Provider.of<BillProvider>(context, listen: false);
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    await auth.ensureInitialized();

    if (!auth.isConfigured || auth.baseUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) _navigateToNext();
      return;
    }

    bool productsSynced = false;
    bool billsSynced = false;
    bool customersSynced = false;
    bool expensesSynced = false;
    bool suppliersSynced = false;
    bool notificationsSynced = false;

    final startTime = DateTime.now();

    while (mounted) {
      final futures = <Future<void>>[];

      if (!productsSynced) {
        futures.add(() async {
          final ok = await productProvider.fetchProducts(auth.baseUrl, auth.apiKey);
          if (ok) productsSynced = true;
        }());
      }

      if (!billsSynced) {
        futures.add(() async {
          final ok = await billProvider.fetchBills(auth.apiService);
          if (ok) billsSynced = true;
        }());
      }

      if (!customersSynced) {
        futures.add(() async {
          final ok = await customerProvider.fetchCustomers(auth.apiService);
          if (ok) customersSynced = true;
        }());
      }

      if (!expensesSynced) {
        futures.add(() async {
          final ok = await expenseProvider.fetchExpenses(auth.apiService);
          if (ok) expensesSynced = true;
        }());
      }

      if (!suppliersSynced) {
        futures.add(() async {
          final ok = await supplierProvider.fetchSuppliers(auth.apiService);
          if (ok) suppliersSynced = true;
        }());
      }

      if (!notificationsSynced) {
        futures.add(() async {
          final ok = await notificationProvider.fetchNotifications(auth.apiService);
          if (ok) notificationsSynced = true;
        }());
      }

      await Future.wait(futures);

      if (productsSynced &&
          billsSynced &&
          customersSynced &&
          expensesSynced &&
          suppliersSynced &&
          notificationsSynced) {
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;
        if (elapsed < 900) {
          await Future.delayed(Duration(milliseconds: 900 - elapsed));
        }
        if (mounted) _navigateToNext();
        return;
      }

      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  void _navigateToNext() {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
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
