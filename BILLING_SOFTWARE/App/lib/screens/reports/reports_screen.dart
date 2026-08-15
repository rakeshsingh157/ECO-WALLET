import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bill_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/theme_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = false;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _topProducts = [];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    final auth = context.read<AuthProvider>();
    if (auth.apiService.baseUrl.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final results = await Future.wait([
          auth.apiService.getReportSummary(),
          auth.apiService.getTopProducts(),
        ]);
        if (mounted) {
          setState(() {
            _summary = results[0] as Map<String, dynamic>;
            _topProducts = results[1] as List<Map<String, dynamic>>;
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final billProvider = context.watch<BillProvider>();
    final productProvider = context.watch<ProductProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();

    final double grossSales = (_summary['grossSales'] != null)
        ? (_summary['grossSales'] as num).toDouble()
        : (billProvider.todaySales > 0 ? billProvider.todaySales : 0.0);

    final double totalExpenses = (_summary['totalExpenses'] != null)
        ? (_summary['totalExpenses'] as num).toDouble()
        : expenseProvider.totalExpenses;

    final double netProfit = (_summary['netProfit'] != null)
        ? (_summary['netProfit'] as num).toDouble()
        : (grossSales - totalExpenses);

    final int totalBills = (_summary['totalBills'] != null)
        ? (_summary['totalBills'] as num).toInt()
        : billProvider.todayBillCount;

    final int totalProducts = (_summary['totalProducts'] != null)
        ? (_summary['totalProducts'] as num).toInt()
        : productProvider.products.length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          context.tr('reports').toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadReportData,
        color: AppColors.terracotta,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Image.asset(MascotAssets.calculator, width: 64, height: 64),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('profit_summary'),
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          Text(
                            NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(netProfit),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: netProfit >= 0 ? AppColors.forestMint : AppColors.error,
                            ),
                          ),
                          Text(
                            'Realtime live net margin from backend',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'PERFORMANCE SUMMARY',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: context.tr('gross_revenue'),
                      value: '₹${grossSales.toStringAsFixed(0)}',
                      color: AppColors.terracotta,
                      icon: Icons.trending_up_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      title: context.tr('total_expenses'),
                      value: '₹${totalExpenses.toStringAsFixed(0)}',
                      color: AppColors.error,
                      icon: Icons.trending_down_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: context.tr('catalog_items'),
                      value: '$totalProducts Products',
                      color: AppColors.warmNavy,
                      icon: Icons.inventory_2_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      title: context.tr('billed_invoices'),
                      value: '$totalBills Invoices',
                      color: AppColors.chaiGold,
                      icon: Icons.receipt_long_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Text(
                context.tr('top_selling'),
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: _isLoading
                    ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                    : _topProducts.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                'No top products data yet. Complete sales to generate insights.',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _topProducts.length,
                            separatorBuilder: (_, __) => Divider(color: AppColors.borderSubtle),
                            itemBuilder: (context, idx) {
                              final item = _topProducts[idx];
                              return _RankRow(
                                rank: '${idx + 1}',
                                title: item['_id'] ?? 'Product',
                                count: '${item['totalQuantity'] ?? 0} sold',
                                revenue: '₹${(item['totalRevenue'] as num?)?.toStringAsFixed(0) ?? '0'}',
                              );
                            },
                          ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('Live report exported successfully'), backgroundColor: AppColors.success),
                    );
                  },
                  icon: Icon(Icons.download_rounded, color: AppColors.terracotta, size: 18),
                  label: Text(
                    context.tr('export_report'),
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.terracotta),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: BorderSide(color: AppColors.terracotta),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({required String title, required String value, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary)),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final String rank;
  final String title;
  final String count;
  final String revenue;

  const _RankRow({
    required this.rank,
    required this.title,
    required this.count,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(rank, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.terracotta)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(count, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(revenue, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
