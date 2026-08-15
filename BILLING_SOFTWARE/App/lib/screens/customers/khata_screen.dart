import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../models/customer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/theme_provider.dart';
import 'customer_details_screen.dart';

class KhataScreen extends StatefulWidget {
  const KhataScreen({super.key});

  @override
  State<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends State<KhataScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshKhata();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshKhata() async {
    final auth = context.read<AuthProvider>();
    if (auth.apiService.baseUrl.isNotEmpty) {
      await context.read<CustomerProvider>().fetchCustomers(auth.apiService);
    }
  }

  void _showAddCreditModal() {
    final customerProvider = context.read<CustomerProvider>();
    Customer? selectedCustomer = customerProvider.customers.isNotEmpty ? customerProvider.customers.first : null;
    final amountCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final aadhaarCtrl = TextEditingController();
    bool isNewCustomer = customerProvider.customers.isEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ctx.tr('add_credit_entry'),
                      style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (customerProvider.customers.isNotEmpty)
                  Row(
                    children: [
                      ChoiceChip(
                        label: Text('Existing Customer', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                        selected: !isNewCustomer,
                        selectedColor: AppColors.terracotta,
                        labelStyle: TextStyle(color: !isNewCustomer ? Colors.white : AppColors.textPrimary),
                        onSelected: (val) => setModalState(() => isNewCustomer = false),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text('+ New Customer', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                        selected: isNewCustomer,
                        selectedColor: AppColors.terracotta,
                        labelStyle: TextStyle(color: isNewCustomer ? Colors.white : AppColors.textPrimary),
                        onSelected: (val) => setModalState(() => isNewCustomer = true),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),

                if (!isNewCustomer && customerProvider.customers.isNotEmpty) ...[
                  DropdownButtonFormField<Customer>(
                    initialValue: selectedCustomer,
                    decoration: InputDecoration(
                      labelText: ctx.tr('select_customer'),
                      prefixIcon: Icon(Icons.person_rounded, color: AppColors.terracotta),
                    ),
                    items: customerProvider.customers
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text('${c.name} (${c.phone})', style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary)),
                            ))
                        .toList(),
                    onChanged: (v) => setModalState(() => selectedCustomer = v),
                  ),
                ] else ...[
                  TextField(
                    controller: nameCtrl,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: ctx.tr('customer_name'),
                      prefixIcon: Icon(Icons.person_rounded, color: AppColors.terracotta),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: ctx.tr('customer_phone'),
                      prefixIcon: Icon(Icons.phone_rounded, color: AppColors.terracotta),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressCtrl,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: ctx.tr('customer_address_optional'),
                      prefixIcon: Icon(Icons.location_on_rounded, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: aadhaarCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: ctx.tr('customer_aadhaar_optional'),
                      counterText: '',
                      prefixIcon: Icon(Icons.badge_rounded, color: AppColors.forestMint),
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  decoration: InputDecoration(labelText: '${ctx.tr('khata_credit')} (₹) *', prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppColors.chaiGold)),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                      if (amt <= 0) return;

                      final auth = context.read<AuthProvider>();

                      if (isNewCustomer) {
                        final n = nameCtrl.text.trim();
                        final p = phoneCtrl.text.trim();
                        if (n.isNotEmpty && p.isNotEmpty) {
                          final newCust = Customer(
                            id: 'cust_${DateTime.now().millisecondsSinceEpoch}',
                            name: n,
                            phone: p,
                            address: addressCtrl.text.trim(),
                            aadhaarNumber: aadhaarCtrl.text.trim(),
                            dueAmount: amt,
                          );
                          await customerProvider.addCustomer(auth.apiService, newCust);
                          await customerProvider.addCredit(auth.apiService, newCust.id, amt);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                        }
                      } else if (selectedCustomer != null) {
                        await customerProvider.addCredit(auth.apiService, selectedCustomer!.id, amt);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                      }
                    },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('RECORD KHATA CREDIT'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final allCustomers = customerProvider.customers;
    final khataCustomers = allCustomers.where((c) => c.dueAmount > 0).toList();
    final totalDue = customerProvider.totalOutstandingDues;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          context.tr('khata_book').toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: AppColors.terracotta),
            onPressed: _showAddCreditModal,
            tooltip: context.tr('khata_book'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshKhata,
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
                  children: [
                    Image.asset(MascotAssets.coin, width: 56, height: 56),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('total_credit_due'),
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${totalDue.toStringAsFixed(0)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppColors.chaiGold,
                            ),
                          ),
                          Text(
                            '${khataCustomers.length} customers with pending udhar',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
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
                onChanged: (v) => customerProvider.setSearchQuery(v),
                style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: context.tr('search_customer'),
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.terracotta),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, size: 18, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchCtrl.clear();
                            customerProvider.setSearchQuery('');
                          },
                        )
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: customerProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : khataCustomers.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(MascotAssets.shopkeeper, width: 80, height: 80),
                                const SizedBox(height: 14),
                                Text(
                                  'No Pending Udhar!',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'All customer dues have been cleared. Outstanding credit balance is zero.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: khataCustomers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final c = khataCustomers[index];
                            return InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => CustomerDetailsScreen(customer: c)),
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
                                          c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
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
                                            c.name,
                                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            c.phone,
                                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹${c.dueAmount.toStringAsFixed(0)}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.chaiGold,
                                          ),
                                        ),
                                        Text(
                                          'Due Balance',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCreditModal,
        backgroundColor: AppColors.terracotta,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('GIVE CREDIT / KHATA', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      ),
    );
  }
}
