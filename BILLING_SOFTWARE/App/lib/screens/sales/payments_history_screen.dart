import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../models/bill.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bill_provider.dart';
import '../../providers/theme_provider.dart';
import 'sale_details_screen.dart';

class PaymentsHistoryScreen extends StatefulWidget {
  const PaymentsHistoryScreen({super.key});

  @override
  State<PaymentsHistoryScreen> createState() => _PaymentsHistoryScreenState();
}

class _PaymentsHistoryScreenState extends State<PaymentsHistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedPeriod = 'All Time';
  String _selectedMode = 'All';
  String _selectedStatus = 'All';

  final List<String> _periodFilters = ['Today', 'This Week', 'This Month', 'All Time'];
  final List<String> _modeFilters = ['All', 'Cash', 'UPI', 'ECO Wallet', 'Khata'];
  final List<String> _statusFilters = ['All', 'Completed', 'Pending Khata', 'Returned'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final auth = context.read<AuthProvider>();
    await context.read<BillProvider>().fetchBills(auth.apiService);
  }

  List<Bill> _getFilteredBills(List<Bill> allBills) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final now = DateTime.now();

    return allBills.where((b) {
      if (_selectedPeriod == 'Today') {
        if (b.timestamp.year != now.year ||
            b.timestamp.month != now.month ||
            b.timestamp.day != now.day) {
          return false;
        }
      } else if (_selectedPeriod == 'This Week') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final cleanStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        if (b.timestamp.isBefore(cleanStart)) {
          return false;
        }
      } else if (_selectedPeriod == 'This Month') {
        if (b.timestamp.year != now.year || b.timestamp.month != now.month) {
          return false;
        }
      }

      if (_selectedMode != 'All') {
        final m = b.paymentMode.name.toLowerCase();
        if (_selectedMode == 'Cash' && m != 'cash') return false;
        if (_selectedMode == 'UPI' && m != 'upi') return false;
        if (_selectedMode == 'ECO Wallet' && !m.contains('wallet') && !m.contains('eco')) return false;
        if (_selectedMode == 'Khata' && m != 'pending') return false;
      }

      if (_selectedStatus != 'All') {
        if (_selectedStatus == 'Completed' && b.status != BillStatus.completed) return false;
        if (_selectedStatus == 'Pending Khata' && b.status != BillStatus.pending) return false;
        if (_selectedStatus == 'Returned' && b.status != BillStatus.returned && b.status != BillStatus.partiallyReturned) return false;
      }

      if (query.isNotEmpty) {
        final name = (b.customerName ?? '').toLowerCase();
        final phone = (b.customerPhone ?? '').toLowerCase();
        final id = b.billId.toLowerCase();
        final mode = b.paymentMode.name.toLowerCase();
        if (!name.contains(query) &&
            !phone.contains(query) &&
            !id.contains(query) &&
            !mode.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Color _getModeColor(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash:
        return AppColors.forestMint;
      case PaymentMode.upi:
        return const Color(0xFF6C5CE7);
      case PaymentMode.ecoWallet:
        return AppColors.terracotta;
      case PaymentMode.pending:
        return AppColors.chaiGold;
    }
  }

  IconData _getModeIcon(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash:
        return Icons.payments_rounded;
      case PaymentMode.upi:
        return Icons.qr_code_2_rounded;
      case PaymentMode.ecoWallet:
        return Icons.account_balance_wallet_rounded;
      case PaymentMode.pending:
        return Icons.pending_actions_rounded;
    }
  }

  String _getFilterLabel(BuildContext context, String filter) {
    switch (filter) {
      case 'Today':
        return context.tr('today');
      case 'This Week':
        return context.tr('this_week');
      case 'This Month':
        return context.tr('this_month');
      case 'All Time':
        return context.tr('all_time');
      case 'All':
        return context.tr('all_categories');
      case 'Cash':
        return context.tr('cash');
      case 'UPI':
        return context.tr('upi');
      case 'ECO Wallet':
        return context.tr('eco_wallet');
      case 'Khata':
        return context.tr('khata_credit');
      case 'Completed':
        return context.tr('completed');
      case 'Pending Khata':
        return context.tr('pending_khata');
      case 'Returned':
        return context.tr('returned');
      default:
        return filter;
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final billProvider = context.watch<BillProvider>();
    final allBills = billProvider.completedBills;
    final filteredBills = _getFilteredBills(allBills);

    final totalCollected = filteredBills
        .where((b) => b.status == BillStatus.completed || b.status == BillStatus.partiallyReturned)
        .fold(0.0, (sum, b) => sum + (b.totalAmount - b.refundedAmount));

    final totalPending = filteredBills
        .where((b) => b.status == BillStatus.pending)
        .fold(0.0, (sum, b) => sum + b.totalAmount);

    final totalRefunded = filteredBills
        .fold(0.0, (sum, b) => sum + b.refundedAmount);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          context.tr('payments_invoices').toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.terracotta,
        backgroundColor: AppColors.surface,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: context.tr('search_payment_placeholder'),
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.terracotta, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('collected'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: AppColors.forestMint,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(totalCollected),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('pending_khata'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: AppColors.chaiGold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(totalPending),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.chaiGold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (totalRefunded > 0) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('refunded'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(totalRefunded),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.error,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    ..._periodFilters.map((period) {
                      final isSelected = _selectedPeriod == period;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(_getFilterLabel(context, period)),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedPeriod = period),
                          selectedColor: AppColors.primaryContainer,
                          backgroundColor: AppColors.surface,
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? AppColors.terracotta : AppColors.textSecondary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: isSelected ? AppColors.terracotta : AppColors.borderSubtle),
                          ),
                        ),
                      );
                    }),
                    Container(height: 20, width: 1, color: AppColors.borderSubtle, margin: const EdgeInsets.symmetric(horizontal: 4)),
                    ..._modeFilters.map((mode) {
                      final isSelected = _selectedMode == mode;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(_getFilterLabel(context, mode)),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedMode = mode),
                          selectedColor: AppColors.primaryContainer,
                          backgroundColor: AppColors.surface,
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? AppColors.terracotta : AppColors.textSecondary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: isSelected ? AppColors.terracotta : AppColors.borderSubtle),
                          ),
                        ),
                      );
                    }),
                    Container(height: 20, width: 1, color: AppColors.borderSubtle, margin: const EdgeInsets.symmetric(horizontal: 4)),
                    ..._statusFilters.map((status) {
                      final isSelected = _selectedStatus == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(_getFilterLabel(context, status)),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedStatus = status),
                          selectedColor: AppColors.primaryContainer,
                          backgroundColor: AppColors.surface,
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? AppColors.terracotta : AppColors.textSecondary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: isSelected ? AppColors.terracotta : AppColors.borderSubtle),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            Expanded(
              child: filteredBills.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(MascotAssets.receipt, width: 72, height: 72),
                            const SizedBox(height: 12),
                            Text(
                              context.tr('no_transactions'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr('change_filter'),
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      itemCount: filteredBills.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final bill = filteredBills[index];
                        final isReturned = bill.isReturned;
                        final isPartial = bill.isPartiallyReturned;
                        final isPending = bill.status == BillStatus.pending;
                        final modeColor = _getModeColor(bill.paymentMode);
                        final modeIcon = _getModeIcon(bill.paymentMode);

                        return InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SaleDetailsScreen(bill: bill)),
                          ),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isReturned
                                    ? AppColors.error.withValues(alpha: 0.3)
                                    : (isPending
                                        ? AppColors.chaiGold.withValues(alpha: 0.4)
                                        : (isPartial
                                            ? AppColors.warning.withValues(alpha: 0.3)
                                            : AppColors.borderSubtle)),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: modeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(modeIcon, color: modeColor, size: 20),
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
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isPending) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.chaiGold.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                context.tr('pending_khata').toUpperCase(),
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.chaiGold,
                                                ),
                                              ),
                                            ),
                                          ] else if (isReturned) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.error.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                context.tr('returned').toUpperCase(),
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
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.warning.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                context.tr('partial_return').toUpperCase(),
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
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: modeColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              bill.paymentMode.name.toUpperCase(),
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: modeColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            DateFormat('dd MMM yyyy, hh:mm a').format(bill.timestamp),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (bill.customerPhone != null && bill.customerPhone!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Ph: ${bill.customerPhone}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(isReturned ? bill.refundedAmount : (isPartial ? bill.netAmount : bill.totalAmount)),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: isReturned
                                            ? AppColors.error
                                            : (isPending ? AppColors.chaiGold : AppColors.textPrimary),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${bill.items.length} ${bill.items.length == 1 ? context.tr('item_unit') : context.tr('items_unit')}',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
