import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/bill_provider.dart';
import '../models/bill.dart';
import 'create_bill_screen.dart';
import 'add_product_screen.dart';
import 'eco_payment_screen.dart';
import 'khata_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final billProvider = context.watch<BillProvider>();

    final todaySales = billProvider.todaySales > 0 ? billProvider.todaySales : 12450.0;
    final todayBills = billProvider.todayBillCount > 0 ? billProvider.todayBillCount : 42;

    return Scaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFF8C75),
                Color(0xFFE8446D),
                AppColors.darkNavy,
                AppColors.darkSurface,
              ],
              stops: [0.0, 0.22, 0.45, 1.0],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Cute Shopkeeper Avatar + Owner Name & Date
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.darkNavy,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.warmPeach, width: 2),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/shopkeeper.png',
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(Icons.person_rounded, color: AppColors.warmCoral),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Namaste, ${auth.ownerName}',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            auth.shopName,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.darkNavy.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        DateFormat('dd MMM yyyy').format(DateTime.now()),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warmPeach,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Today's Sales Glass Card with Cute Coin Character
                GlassCard(
                  padding: const EdgeInsets.all(22),
                  borderRadius: 24,
                  color: AppColors.darkCard.withValues(alpha: 0.94),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "TODAY'S SALES",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.trending_up_rounded, color: AppColors.success, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '+15% vs Yesterday',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '₹${todaySales.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: AppColors.warmPeach,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                '$todayBills Bills Generated',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Cute Coin Mascot Overlay on Card
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Opacity(
                          opacity: 0.85,
                          child: Image.asset(
                            'assets/images/coin.png',
                            width: 68,
                            height: 68,
                            errorBuilder: (c, e, s) => const SizedBox(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Quick Actions Grid (2x2)
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionTile(
                        context,
                        title: 'Create Bill',
                        icon: Icons.add_shopping_cart_rounded,
                        isPrimary: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreateBillScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildQuickActionTile(
                        context,
                        title: 'Add Product',
                        icon: Icons.add_box_rounded,
                        isPrimary: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddProductScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionTile(
                        context,
                        title: 'ECO Payment',
                        icon: Icons.qr_code_2_rounded,
                        isPrimary: false,
                        accentColor: AppColors.warmPeach,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EcoPaymentScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildQuickActionTile(
                        context,
                        title: 'Khata Book',
                        icon: Icons.menu_book_rounded,
                        isPrimary: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const KhataScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Low Stock Alert Banner
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  borderRadius: 16,
                  color: AppColors.warning.withValues(alpha: 0.12),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '3 Items Low Stock',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning,
                              ),
                            ),
                            Text(
                              'Turmeric Powder, Bread Loaf, Sunflower Oil',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'View',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Recent Transactions Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Bills',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'See All',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warmCoral,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Recent Bills List
                ...billProvider.completedBills.map((bill) => _buildTransactionItem(bill)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
    Color? accentColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          gradient: isPrimary ? AppColors.sunsetGradient : null,
          color: isPrimary ? null : AppColors.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: isPrimary
              ? null
              : Border.all(color: AppColors.glassBorder.withValues(alpha: 0.4)),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.warmCoral.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPrimary ? Colors.white.withValues(alpha: 0.2) : AppColors.darkCardLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isPrimary ? Colors.white : (accentColor ?? AppColors.warmCoral),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Bill bill) {
    IconData modeIcon;
    Color modeColor;
    String modeLabel;

    switch (bill.paymentMode) {
      case PaymentMode.ecoWallet:
        modeIcon = Icons.stars_rounded;
        modeColor = AppColors.warmPeach;
        modeLabel = 'ECO Wallet';
        break;
      case PaymentMode.upi:
        modeIcon = Icons.qr_code_rounded;
        modeColor = AppColors.info;
        modeLabel = 'UPI';
        break;
      case PaymentMode.pending:
        modeIcon = Icons.pending_actions_rounded;
        modeColor = AppColors.warning;
        modeLabel = 'Pending Khata';
        break;
      case PaymentMode.cash:
      default:
        modeIcon = Icons.payments_rounded;
        modeColor = AppColors.success;
        modeLabel = 'Cash';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: modeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(modeIcon, color: modeColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.customerName ?? 'Bill #${bill.billId}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Bill #${bill.billId} • ${DateFormat('hh:mm a').format(bill.timestamp)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${bill.totalAmount.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: bill.status == BillStatus.pending ? AppColors.warning : AppColors.success,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: modeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  modeLabel,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: modeColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
