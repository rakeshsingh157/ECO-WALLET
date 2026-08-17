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

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  String _selectedFilter = 'Today';
  final List<String> _filters = ['Today', 'This Week', 'This Month', 'All Time'];

  List<Bill> _filterBills(List<Bill> allBills) {
    final now = DateTime.now();
    if (_selectedFilter == 'Today') {
      return allBills.where((b) =>
          b.timestamp.year == now.year &&
          b.timestamp.month == now.month &&
          b.timestamp.day == now.day).toList();
    } else if (_selectedFilter == 'This Week') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final cleanStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      return allBills.where((b) => b.timestamp.isAfter(cleanStart)).toList();
    } else if (_selectedFilter == 'This Month') {
      return allBills.where((b) =>
          b.timestamp.year == now.year &&
          b.timestamp.month == now.month).toList();
    }
    return allBills;
  }

  Future<void> _refreshBills() async {
    final auth = context.read<AuthProvider>();
    await context.read<BillProvider>().fetchBills(auth.apiService);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final billProvider = context.watch<BillProvider>();
    final allBills = billProvider.completedBills;
    final bills = _filterBills(allBills);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          context.tr('sales_history'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshBills,
        color: AppColors.terracotta,
        backgroundColor: AppColors.surface,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _filters.map((f) {
                    final isSelected = _selectedFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f == 'Today'
                            ? context.tr('today')
                            : (f == 'This Week'
                                ? context.tr('this_week')
                                : (f == 'This Month'
                                    ? context.tr('this_month')
                                    : context.tr('all_time')))),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedFilter = f),
                        selectedColor: AppColors.primaryContainer,
                        backgroundColor: AppColors.surface,
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.terracotta : AppColors.textSecondary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: isSelected ? AppColors.terracotta : AppColors.borderSubtle),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Expanded(
              child: bills.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(MascotAssets.receipt, width: 80, height: 80),
                            const SizedBox(height: 14),
                            Text(
                              'No sales recorded yet',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Invoices issued via POS will appear here.',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: bills.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final bill = bills[index];
                        final isReturned = bill.isReturned;
                        final isPartial = bill.isPartiallyReturned;
                        final isPending = bill.status == BillStatus.pending;

                        return InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SaleDetailsScreen(bill: bill)),
                          ),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
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
                                    color: isReturned
                                        ? AppColors.error.withValues(alpha: 0.1)
                                        : (isPending
                                            ? AppColors.chaiGold.withValues(alpha: 0.12)
                                            : (isPartial
                                                ? AppColors.warning.withValues(alpha: 0.1)
                                                : AppColors.primaryContainer)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isReturned
                                        ? Icons.assignment_return_rounded
                                        : (isPending ? Icons.pending_actions_rounded : Icons.receipt_long_rounded),
                                    color: isReturned
                                        ? AppColors.error
                                        : (isPending
                                            ? AppColors.chaiGold
                                            : (isPartial ? AppColors.warning : AppColors.terracotta)),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
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
                                                'PENDING KHATA',
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
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.warning.withValues(alpha: 0.15),
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
                                        '${isPending ? 'KHATA (UNPAID)' : bill.paymentMode.name.toUpperCase()} • ${DateFormat('dd MMM, hh:mm a').format(bill.timestamp)}',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
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
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: isReturned ? AppColors.error : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${bill.items.length} items',
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
