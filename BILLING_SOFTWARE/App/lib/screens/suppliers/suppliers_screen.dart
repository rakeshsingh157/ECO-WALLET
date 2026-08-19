import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../models/supplier.dart';
import '../../providers/auth_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/theme_provider.dart';
import 'supplier_details_screen.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshSuppliers();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshSuppliers() async {
    final auth = context.read<AuthProvider>();
    if (auth.apiService.baseUrl.isNotEmpty) {
      await context.read<SupplierProvider>().fetchSuppliers(auth.apiService);
    }
  }

  void _showAddSupplierModal() {
    final nameCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final gstinCtrl = TextEditingController();

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark || AppColors.isDark;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 14,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF37475A) : const Color(0xFFD5CEBF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.warmNavy.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.domain_add_rounded, size: 20, color: AppColors.warmNavy),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            ctx.tr('add_supplier').toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                        onPressed: isSaving ? null : () => Navigator.pop(ctx),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1B2432) : const Color(0xFFF9F7F4),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? const Color(0xFF2B3A4F) : const Color(0xFFE8E2D8),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'Contact Person Name *',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        TextField(
                          controller: nameCtrl,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. Rajesh Sharma',
                            prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.terracotta, size: 20),
                          ),
                        ),

                        const SizedBox(height: 14),

                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'Business / Company Name *',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        TextField(
                          controller: companyCtrl,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. Apex Traders Ltd.',
                            prefixIcon: Icon(Icons.business_outlined, color: AppColors.warmNavy, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1B2432) : const Color(0xFFF9F7F4),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? const Color(0xFF2B3A4F) : const Color(0xFFE8E2D8),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'Phone Number *',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        TextField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            hintText: '10-digit mobile number',
                            prefixIcon: Icon(Icons.phone_outlined, color: AppColors.forestMint, size: 20),
                          ),
                        ),

                        const SizedBox(height: 14),

                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'GSTIN (Optional)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        TextField(
                          controller: gstinCtrl,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. 27AAAAA0000A1Z5',
                            prefixIcon: Icon(Icons.badge_outlined, color: AppColors.chaiGold, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              final company = companyCtrl.text.trim();
                              final phone = phoneCtrl.text.trim();

                              if (name.isEmpty || company.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(context.tr('contact_company_required')),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);
                              final auth = context.read<AuthProvider>();
                              final newSupplier = Supplier(
                                id: 'sup_${DateTime.now().millisecondsSinceEpoch}',
                                name: name,
                                companyName: company,
                                phone: phone,
                                gstin: gstinCtrl.text.trim(),
                              );
                              await context.read<SupplierProvider>().addSupplier(auth.apiService, newSupplier);
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                            },
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_rounded, size: 20),
                      label: Text(
                        isSaving ? 'SAVING SUPPLIER...' : 'SAVE SUPPLIER PROFILE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracotta,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final supplierProvider = context.watch<SupplierProvider>();
    final suppliers = supplierProvider.suppliers;
    final totalPayables = supplierProvider.totalPendingPayable;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          context.tr('suppliers').toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_rounded, color: AppColors.terracotta),
            onPressed: _showAddSupplierModal,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSuppliers,
        color: AppColors.terracotta,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('pending_payment').toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${totalPayables.toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.error),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddSupplierModal,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(context.tr('add_supplier')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracotta,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => supplierProvider.setSearchQuery(v),
                style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: context.tr('search_supplier'),
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.terracotta),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, size: 18, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchCtrl.clear();
                            supplierProvider.setSearchQuery('');
                          },
                        )
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: supplierProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : suppliers.isEmpty
                      ? Center(
                          child: Text(context.tr('no_suppliers_found'), style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: suppliers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final s = suppliers[index];
                            return InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => SupplierDetailsScreen(supplier: s)),
                              ),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.borderSubtle),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryContainer,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          s.companyName.isNotEmpty ? s.companyName[0].toUpperCase() : 'V',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.terracotta),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s.companyName,
                                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                          ),
                                          Text(
                                            '${s.name} • ${s.phone}',
                                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          s.pendingPayment > 0 ? '₹${s.pendingPayment.toStringAsFixed(0)}' : 'Paid',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: s.pendingPayment > 0 ? AppColors.error : AppColors.forestMint,
                                          ),
                                        ),
                                        Text(
                                          s.pendingPayment > 0 ? 'Payable' : 'All Clear',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textMuted),
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
