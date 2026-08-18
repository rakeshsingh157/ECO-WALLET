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

  bool _isSyncComplete = false;
  Timer? _syncLoopTimer;

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
    _startPersistentDataSync();
  }

  void _startPersistentDataSync() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final billProvider = Provider.of<BillProvider>(context, listen: false);
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    if (!auth.isConfigured || auth.baseUrl.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 1600));
      if (mounted) _navigateToNext();
      return;
    }

    while (mounted && !_isSyncComplete) {
      _attemptCount++;
      if (mounted) {
        setState(() {
          if (_attemptCount == 1) {
            _statusMessage = 'Connecting to Dukaan Dost Cloud...';
          } else if (_attemptCount <= 3) {
            _statusMessage = 'Waking up cloud server (attempt $_attemptCount)...';
          } else {
            _statusMessage = 'Receiving all store data (attempt $_attemptCount)...';
          }
        });
      }

      final futures = <Future<void>>[];

      if (!_productsSynced) {
        futures.add(() async {
          try {
            await productProvider.fetchProducts(auth.baseUrl, auth.apiKey);
            if (mounted) setState(() => _productsSynced = true);
          } catch (_) {}
        }());
      }

      if (!_billsSynced) {
        futures.add(() async {
          try {
            await billProvider.fetchBills(auth.apiService);
            if (mounted) setState(() => _billsSynced = true);
          } catch (_) {}
        }());
      }

      if (!_customersSynced) {
        futures.add(() async {
          try {
            await customerProvider.fetchCustomers(auth.apiService);
            if (mounted) setState(() => _customersSynced = true);
          } catch (_) {}
        }());
      }

      if (!_expensesSynced) {
        futures.add(() async {
          try {
            await expenseProvider.fetchExpenses(auth.apiService);
            if (mounted) setState(() => _expensesSynced = true);
          } catch (_) {}
        }());
      }

      if (!_suppliersSynced) {
        futures.add(() async {
          try {
            await supplierProvider.fetchSuppliers(auth.apiService);
            if (mounted) setState(() => _suppliersSynced = true);
          } catch (_) {}
        }());
      }

      if (!_notificationsSynced) {
        futures.add(() async {
          try {
            await notificationProvider.fetchNotifications(auth.apiService);
            if (mounted) setState(() => _notificationsSynced = true);
          } catch (_) {}
        }());
      }

      await Future.wait(futures);

      if (_productsSynced &&
          _billsSynced &&
          _customersSynced &&
          _expensesSynced &&
          _suppliersSynced &&
          _notificationsSynced) {
        _isSyncComplete = true;
        if (mounted) {
          setState(() => _statusMessage = 'All store records synchronized successfully!');
        }
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) _navigateToNext();
        break;
      }

      await Future.delayed(const Duration(seconds: 2));
    }
  }

  void _navigateToNext() {
    _syncLoopTimer?.cancel();
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
    _syncLoopTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  int get _syncedCount {
    int count = 0;
    if (_productsSynced) count++;
    if (_billsSynced) count++;
    if (_customersSynced) count++;
    if (_expensesSynced) count++;
    if (_suppliersSynced) count++;
    if (_notificationsSynced) count++;
    return count;
  }

  Widget _buildSyncItem(String title, bool isSynced) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: isSynced ? AppColors.forestMint : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSynced ? AppColors.forestMint : AppColors.borderSubtle,
                width: 1.5,
              ),
            ),
            child: isSynced
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 12)
                : Center(
                    child: SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.terracotta,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSynced ? FontWeight.w700 : FontWeight.w500,
                color: isSynced ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
          if (isSynced)
            Text(
              'READY',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.forestMint,
              ),
            )
          else
            Text(
              'LOADING',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.terracotta,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      MascotAssets.shopkeeper,
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 18),

                    Text(
                      'DUKAAN DOST',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      'Smart Retail POS & Khata Terminal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderSubtle, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _isSyncComplete ? AppColors.forestMint : AppColors.terracotta,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'SYNCHRONIZING STORE DATA',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.1,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.terracotta.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$_syncedCount / 6',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.terracotta,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _syncedCount / 6.0,
                              minHeight: 6,
                              backgroundColor: AppColors.canvas,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _isSyncComplete ? AppColors.forestMint : AppColors.terracotta,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildSyncItem('Products & Catalog Inventory', _productsSynced),
                          _buildSyncItem('Sales Records & Bill History', _billsSynced),
                          _buildSyncItem('Customer Directory & Khata Ledger', _customersSynced),
                          _buildSyncItem('Store Overhead & Expense Logs', _expensesSynced),
                          _buildSyncItem('Suppliers & Purchase Accounts', _suppliersSynced),
                          _buildSyncItem('Notifications & System Alerts', _notificationsSynced),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

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

                    if (_attemptCount > 4) ...[
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _navigateToNext,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('Continue to Dashboard (Background Sync)'),
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
