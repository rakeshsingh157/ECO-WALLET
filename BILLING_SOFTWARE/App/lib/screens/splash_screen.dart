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
  int _attemptCount = 0;

  bool _productsSynced = false;
  bool _billsSynced = false;
  bool _customersSynced = false;
  bool _expensesSynced = false;
  bool _suppliersSynced = false;
  bool _notificationsSynced = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _startPersistentDataSync();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startPersistentDataSync() async {
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

    while (mounted) {
      _attemptCount++;
      if (mounted) {
        setState(() {
          if (_attemptCount == 1) {
            _statusMessage = 'Connecting to Dukaan Dost Cloud...';
          } else {
            _statusMessage = 'Waking up cloud server and receiving store data (attempt $_attemptCount)...';
          }
        });
      }

      final futures = <Future<void>>[];

      if (!_productsSynced) {
        futures.add(() async {
          final ok = await productProvider.fetchProducts(auth.baseUrl, auth.apiKey);
          if (ok && mounted) setState(() => _productsSynced = true);
        }());
      }

      if (!_billsSynced) {
        futures.add(() async {
          final ok = await billProvider.fetchBills(auth.apiService);
          if (ok && mounted) setState(() => _billsSynced = true);
        }());
      }

      if (!_customersSynced) {
        futures.add(() async {
          final ok = await customerProvider.fetchCustomers(auth.apiService);
          if (ok && mounted) setState(() => _customersSynced = true);
        }());
      }

      if (!_expensesSynced) {
        futures.add(() async {
          final ok = await expenseProvider.fetchExpenses(auth.apiService);
          if (ok && mounted) setState(() => _expensesSynced = true);
        }());
      }

      if (!_suppliersSynced) {
        futures.add(() async {
          final ok = await supplierProvider.fetchSuppliers(auth.apiService);
          if (ok && mounted) setState(() => _suppliersSynced = true);
        }());
      }

      if (!_notificationsSynced) {
        futures.add(() async {
          final ok = await notificationProvider.fetchNotifications(auth.apiService);
          if (ok && mounted) setState(() => _notificationsSynced = true);
        }());
      }

      await Future.wait(futures);

      if (_productsSynced &&
          _billsSynced &&
          _customersSynced &&
          _expensesSynced &&
          _suppliersSynced &&
          _notificationsSynced) {
        if (mounted) {
          setState(() => _statusMessage = 'All store data received successfully!');
        }
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) _navigateToNext();
        return;
      }

      await Future.delayed(const Duration(milliseconds: 1500));
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
    final syncedCount = (_productsSynced ? 1 : 0) +
        (_billsSynced ? 1 : 0) +
        (_customersSynced ? 1 : 0) +
        (_expensesSynced ? 1 : 0) +
        (_suppliersSynced ? 1 : 0) +
        (_notificationsSynced ? 1 : 0);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.borderSubtle, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.terracotta.withValues(alpha: 0.18),
                            blurRadius: 36,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(Icons.storefront_rounded, size: 54, color: AppColors.terracotta),
                        ),
                      ),
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
                      'Smart Billing for Smart Shopkeepers',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const Spacer(flex: 2),

                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.terracotta),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      _statusMessage,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 10),

                    if (syncedCount > 0)
                      Text(
                        'Loaded $syncedCount / 6 store modules',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.forestMint,
                        ),
                      ),

                    const SizedBox(height: 48),
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
