import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bill_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/bill.dart';
import '../pos/pos_screen.dart';
import '../inventory/add_product_screen.dart';
import '../expenses/expenses_screen.dart';
import '../inventory/low_stock_screen.dart';
import '../customers/khata_screen.dart';
import '../reports/reports_screen.dart';
import '../notifications/notifications_screen.dart';
import '../sales/return_order_screen.dart';
import '../sales/sale_details_screen.dart';
import '../sales/payments_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final auth = context.read<AuthProvider>();
    if (auth.baseUrl.isNotEmpty) {
      await Future.wait([
        context.read<ProductProvider>().fetchProducts(auth.baseUrl, auth.apiKey),
        context.read<BillProvider>().fetchBills(auth.apiService),
      ]);
    }
  }

  String _getTimeGreeting(LocaleProvider localeProvider) {
    final hour = DateTime.now().hour;
    if (localeProvider.isHindi) {
      if (hour < 12) return 'शुभ प्रभात';
      if (hour < 17) return 'नमस्ते';
      return 'शुभ संध्या';
    }
    if (localeProvider.isMarathi) {
      if (hour < 12) return 'शुभ सकाळ';
      if (hour < 17) return 'नमस्कार';
      return 'शुभ संध्याकाळ';
    }
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final billProvider = context.watch<BillProvider>();
    final productProvider = context.watch<ProductProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final localeProvider = context.watch<LocaleProvider>();

    final todaySales = billProvider.todaySales;
    final todayBills = billProvider.todayBillCount;
    final lowStockItems = productProvider.lowStockProducts;
    final totalKhataDues = customerProvider.totalOutstandingDues;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: AppColors.terracotta,
          backgroundColor: AppColors.surface,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          MascotAssets.shopkeeper,
                          width: 44,
                          height: 44,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_getTimeGreeting(localeProvider)}, ${auth.isStaff && auth.staffName.isNotEmpty ? auth.staffName : (auth.ownerName.isNotEmpty ? auth.ownerName : 'Dukaandar')}!',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  auth.shopName.isNotEmpty ? auth.shopName : 'My Retail Store',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (auth.isStaff) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.forestMint.withAlpha(25),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.forestMint.withAlpha(80)),
                                    ),
                                    child: Text(
                                      auth.staffRole.isNotEmpty ? auth.staffRole.toUpperCase() : 'STAFF',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.forestMint,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.insights_rounded, color: AppColors.terracotta),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ReportsScreen()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            localeProvider.tr('today_sales').toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: AppColors.forestMint,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'LIVE',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.forestMint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(todaySales),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.terracotta,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Divider(color: AppColors.borderSubtle),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  localeProvider.tr('completed_bills').toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                                ),
                                Text(
                                  '$todayBills Invoices',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 28, color: AppColors.borderSubtle),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KhataScreen())),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    localeProvider.tr('khata_pending').toUpperCase(),
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                                  ),
                                  Text(
                                    '₹${totalKhataDues.toStringAsFixed(0)}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.chaiGold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(width: 1, height: 28, color: AppColors.borderSubtle),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LowStockScreen())),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    localeProvider.tr('low_stock_items').toUpperCase(),
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                                  ),
                                  Text(
                                    '${lowStockItems.length} Items',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: lowStockItems.isNotEmpty ? AppColors.error : AppColors.forestMint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  localeProvider.tr('quick_actions'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        title: localeProvider.tr('new_bill'),
                        subtitle: 'POS',
                        icon: Icons.add_shopping_cart_rounded,
                        color: AppColors.terracotta,
                        isPrimary: true,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PosScreen())),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionButton(
                        title: localeProvider.tr('add_product'),
                        subtitle: 'SKU',
                        icon: Icons.inventory_2_rounded,
                        color: AppColors.forestMint,
                        isPrimary: false,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen())),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        title: localeProvider.tr('khata_book'),
                        subtitle: 'Credit',
                        icon: Icons.menu_book_rounded,
                        color: AppColors.chaiGold,
                        isPrimary: false,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KhataScreen())),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionButton(
                        title: localeProvider.tr('expenses'),
                        subtitle: 'Ledger',
                        icon: Icons.receipt_long_rounded,
                        color: AppColors.warmNavy,
                        isPrimary: false,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesScreen())),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildActionButton(
                  title: localeProvider.tr('order_returns'),
                  subtitle: localeProvider.tr('search_bill_return'),
                  icon: Icons.assignment_return_rounded,
                  color: AppColors.error,
                  isPrimary: false,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReturnOrderScreen())),
                ),

                const SizedBox(height: 20),

                if (lowStockItems.isNotEmpty) ...[
                  InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LowStockScreen())),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Image.asset(MascotAssets.box, width: 32, height: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${lowStockItems.length} ${localeProvider.tr('low_stock_items')}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.warning),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localeProvider.tr('recent_invoices').toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentsHistoryScreen())),
                      child: Text(
                        localeProvider.tr('view_all_payments'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.terracotta,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (billProvider.isLoadingBills)
                  Center(child: Padding(padding: const EdgeInsets.all(24), child: CircularProgressIndicator(color: AppColors.terracotta)))
                else if (billProvider.completedBills.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      children: [
                        Image.asset(MascotAssets.receipt, width: 64, height: 64),
                        const SizedBox(height: 12),
                        Text(
                          localeProvider.tr('no_bills_today'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          localeProvider.tr('create_first_bill'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: billProvider.completedBills.length > 6 ? 6 : billProvider.completedBills.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final bill = billProvider.completedBills[index];
                      return _buildRecentInvoiceTile(bill);
                    },
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.terracotta : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: isPrimary ? null : Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: (isPrimary ? AppColors.terracotta : const Color(0x06000000)).withValues(alpha: isPrimary ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPrimary ? Colors.white.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isPrimary ? Colors.white : color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isPrimary ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: isPrimary ? Colors.white.withValues(alpha: 0.8) : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentInvoiceTile(Bill bill) {
    final isReturned = bill.isReturned;
    final isPartial = bill.isPartiallyReturned;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SaleDetailsScreen(bill: bill)),
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isReturned
                ? AppColors.error.withAlpha(80)
                : (isPartial ? AppColors.warning.withAlpha(80) : AppColors.borderSubtle),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isReturned
                    ? AppColors.error.withAlpha(25)
                    : (isPartial ? AppColors.warning.withAlpha(25) : AppColors.primaryContainer),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isReturned ? Icons.assignment_return_rounded : Icons.receipt_rounded,
                color: isReturned ? AppColors.error : (isPartial ? AppColors.warning : AppColors.terracotta),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          bill.customerName ?? 'Counter Customer',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isReturned) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error.withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'RETURNED',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ] else if (isPartial) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PARTIAL',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${bill.paymentMode.name.toUpperCase()} • ${DateFormat('hh:mm a').format(bill.timestamp)}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(isReturned ? bill.refundedAmount : (isPartial ? bill.netAmount : bill.totalAmount)),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isReturned ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
                if (isReturned)
                  Text(
                    'Refunded',
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.error),
                  )
                else if (isPartial)
                  Text(
                    'Orig: ₹${bill.totalAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      decoration: TextDecoration.lineThrough,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
