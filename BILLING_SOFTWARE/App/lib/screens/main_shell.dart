import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/bill_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/supplier_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/locale_provider.dart';
import '../core/update_service.dart';
import 'dashboard/dashboard_screen.dart';
import 'inventory/products_screen.dart';
import 'pos/pos_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncAllStoreData();
      UpdateService.checkForUpdates(context);
    });
  }

  Future<void> _syncAllStoreData() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isConfigured || auth.baseUrl.isEmpty) return;

    try {
      await Future.wait([
        context.read<ProductProvider>().fetchProducts(auth.baseUrl, auth.apiKey),
        context.read<BillProvider>().fetchBills(auth.apiService),
        context.read<CustomerProvider>().fetchCustomers(auth.apiService),
        context.read<ExpenseProvider>().fetchExpenses(auth.apiService),
        context.read<SupplierProvider>().fetchSuppliers(auth.apiService),
        context.read<NotificationProvider>().fetchNotifications(auth.apiService),
      ]);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final cartCount = context.watch<BillProvider>().itemCount;
    final localeProvider = context.watch<LocaleProvider>();

    final screens = [
      const DashboardScreen(),
      const ProductsScreen(),
      const PosScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.storefront_outlined,
                  activeIcon: Icons.storefront_rounded,
                  label: localeProvider.tr('home'),
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2_rounded,
                  label: localeProvider.tr('inventory'),
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.point_of_sale_outlined,
                  activeIcon: Icons.point_of_sale_rounded,
                  label: localeProvider.tr('billing'),
                  badgeCount: cartCount,
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.insights_outlined,
                  activeIcon: Icons.insights_rounded,
                  label: localeProvider.tr('reports'),
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.menu_rounded,
                  activeIcon: Icons.menu_open_rounded,
                  label: localeProvider.tr('more'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: badgeCount > 0,
                label: Text(
                  '$badgeCount',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                backgroundColor: AppColors.terracotta,
                child: Icon(
                  isSelected ? activeIcon : icon,
                  size: 22,
                  color: isSelected ? AppColors.terracotta : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.terracotta : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
