import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/app_notifier.dart';
import '../../core/localization.dart';
import '../../models/customer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/bill_provider.dart';
import '../../providers/theme_provider.dart';
import 'customer_details_screen.dart';

class KhataScreen extends StatefulWidget {
  const KhataScreen({super.key});

  @override
  State<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends State<KhataScreen> {
  final _searchCtrl = TextEditingController();
  int _selectedFilterIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<CustomerProvider>().fetchCustomers(auth.apiService);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshKhata() async {
    final auth = context.read<AuthProvider>();
    await context.read<CustomerProvider>().fetchCustomers(auth.apiService);
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
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark || AppColors.isDark;

          return Padding(
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
                              color: AppColors.terracotta.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.add_card_rounded, size: 20, color: AppColors.terracotta),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            ctx.tr('add_credit_entry').toUpperCase(),
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
                        if (customerProvider.customers.isNotEmpty) ...[
                          Row(
                            children: [
                              ChoiceChip(
                                label: Text(ctx.tr('existing_customer')),
                                selected: !isNewCustomer,
                                selectedColor: AppColors.terracotta,
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: !isNewCustomer ? FontWeight.w800 : FontWeight.w600,
                                  color: !isNewCustomer ? Colors.white : AppColors.textPrimary,
                                ),
                                backgroundColor: isDark ? const Color(0xFF243042) : const Color(0xFFEBE6DC),
                                showCheckmark: false,
                                side: BorderSide.none,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                onSelected: isSaving ? null : (_) => setModalState(() => isNewCustomer = false),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: Text('+ ${ctx.tr('new_customer')}'),
                                selected: isNewCustomer,
                                selectedColor: AppColors.terracotta,
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: isNewCustomer ? FontWeight.w800 : FontWeight.w600,
                                  color: isNewCustomer ? Colors.white : AppColors.textPrimary,
                                ),
                                backgroundColor: isDark ? const Color(0xFF243042) : const Color(0xFFEBE6DC),
                                showCheckmark: false,
                                side: BorderSide.none,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                onSelected: isSaving ? null : (_) => setModalState(() => isNewCustomer = true),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],

                        if (!isNewCustomer && customerProvider.customers.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              'Select Customer *',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          DropdownButtonFormField<Customer>(
                            initialValue: selectedCustomer,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.terracotta, size: 20),
                            ),
                            items: customerProvider.customers
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        '${c.name} (${c.phone})',
                                        style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                                      ),
                                    ))
                                .toList(),
                            onChanged: isSaving ? null : (v) => setModalState(() => selectedCustomer = v),
                          ),
                        ] else ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              'Customer Name *',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          TextField(
                            controller: nameCtrl,
                            enabled: !isSaving,
                            style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                            decoration: InputDecoration(
                              hintText: 'e.g. Ramesh Kumar',
                              prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.terracotta, size: 20),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              'Mobile Number *',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          TextField(
                            controller: phoneCtrl,
                            enabled: !isSaving,
                            keyboardType: TextInputType.phone,
                            style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                            decoration: InputDecoration(
                              hintText: '10-digit mobile number',
                              prefixIcon: Icon(Icons.phone_outlined, color: AppColors.forestMint, size: 20),
                            ),
                          ),
                        ],
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
                            'Khata Credit Amount (₹) *',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        TextField(
                          controller: amountCtrl,
                          enabled: !isSaving,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.terracotta,
                          ),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppColors.chaiGold, size: 20),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 8,
                          children: [100, 200, 500, 1000].map((preset) {
                            return ActionChip(
                              label: Text('+₹$preset'),
                              labelStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFD5CEBF) : const Color(0xFF4A443A),
                              ),
                              backgroundColor: isDark ? const Color(0xFF243042) : const Color(0xFFEBE6DC),
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              onPressed: () {
                                final cur = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                                final next = cur + preset;
                                amountCtrl.text = next.truncateToDouble() == next ? next.toInt().toString() : next.toString();
                              },
                            );
                          }).toList(),
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
                              final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                              if (amt <= 0) {
                                AppNotifier.warning(ctx, 'Please enter a valid credit amount', title: 'INVALID AMOUNT');
                                return;
                              }

                              final auth = context.read<AuthProvider>();
                              final billProvider = context.read<BillProvider>();
                              setModalState(() => isSaving = true);

                              try {
                                if (isNewCustomer) {
                                  final n = nameCtrl.text.trim();
                                  final p = phoneCtrl.text.trim();
                                  if (n.isEmpty || p.isEmpty) {
                                    setModalState(() => isSaving = false);
                                    AppNotifier.warning(ctx, 'Customer name and phone are required', title: 'REQUIRED FIELDS');
                                    return;
                                  }
                                  final newCust = Customer(
                                    id: 'cust_${DateTime.now().millisecondsSinceEpoch}',
                                    name: n,
                                    phone: p,
                                    address: addressCtrl.text.trim(),
                                    aadhaarNumber: aadhaarCtrl.text.trim(),
                                    dueAmount: amt,
                                  );
                                  await customerProvider.addCustomer(auth.apiService, newCust);
                                } else if (selectedCustomer != null) {
                                  await customerProvider.addCredit(auth.apiService, selectedCustomer!.id, amt);
                                }

                                billProvider.fetchBills(auth.apiService);

                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                if (mounted) {
                                  AppNotifier.success(
                                    context,
                                    'Recorded ₹${amt.toStringAsFixed(0)} Khata credit successfully',
                                    title: 'KHATA RECORDED',
                                  );
                                }
                              } catch (_) {
                                if (ctx.mounted) {
                                  setModalState(() => isSaving = false);
                                  AppNotifier.error(
                                    ctx,
                                    'Failed to record Khata credit. Please check connection.',
                                    title: 'SYNC ERROR',
                                  );
                                }
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
                        isSaving ? 'SAVING CREDIT...' : 'CONFIRM KHATA CREDIT',
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
    final customerProvider = context.watch<CustomerProvider>();
    final allCustomers = customerProvider.customers;
    final pendingCustomers = allCustomers.where((c) => c.dueAmount > 0).toList();
    final settledCustomers = allCustomers.where((c) => c.dueAmount <= 0).toList();

    final displayedCustomers = _selectedFilterIndex == 0
        ? pendingCustomers
        : (_selectedFilterIndex == 1 ? settledCustomers : allCustomers);

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
                            '${pendingCustomers.length} ${context.tr('pending_khata')} • ${settledCustomers.length} ${context.tr('cleared')}',
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

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('${context.tr('pending_khata')} (${pendingCustomers.length})'),
                    selected: _selectedFilterIndex == 0,
                    selectedColor: AppColors.terracotta,
                    labelStyle: TextStyle(
                      color: _selectedFilterIndex == 0 ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                    onSelected: (_) => setState(() => _selectedFilterIndex = 0),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('${context.tr('settled')} (${settledCustomers.length})'),
                    selected: _selectedFilterIndex == 1,
                    selectedColor: AppColors.forestMint,
                    labelStyle: TextStyle(
                      color: _selectedFilterIndex == 1 ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                    onSelected: (_) => setState(() => _selectedFilterIndex = 1),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('${context.tr('all')} (${allCustomers.length})'),
                    selected: _selectedFilterIndex == 2,
                    selectedColor: AppColors.textPrimary,
                    labelStyle: TextStyle(
                      color: _selectedFilterIndex == 2 ? AppColors.surface : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                    onSelected: (_) => setState(() => _selectedFilterIndex = 2),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: customerProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayedCustomers.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(MascotAssets.shopkeeper, width: 80, height: 80),
                                const SizedBox(height: 14),
                                Text(
                                  _selectedFilterIndex == 0 ? context.tr('all_dues_cleared') : context.tr('no_customers_found'),
                                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedFilterIndex == 0
                                      ? context.tr('all_dues_cleared_sub')
                                      : context.tr('no_customers_found'),
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
                          itemCount: displayedCustomers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final c = displayedCustomers[index];
                            final isSettled = c.dueAmount <= 0;

                            return InkWell(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => CustomerDetailsScreen(customer: c)),
                                );
                                if (mounted) {
                                  _refreshKhata();
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSettled ? AppColors.forestMint.withAlpha(50) : AppColors.borderSubtle,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isSettled ? AppColors.forestMint.withAlpha(25) : AppColors.primaryContainer,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: isSettled ? AppColors.forestMint : AppColors.terracotta,
                                          ),
                                        ),
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
                                                  c.name,
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isSettled) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.forestMint.withAlpha(25),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'CLEARED',
                                                    style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.forestMint),
                                                  ),
                                                ),
                                              ],
                                            ],
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
                                            color: isSettled ? AppColors.forestMint : AppColors.chaiGold,
                                          ),
                                        ),
                                        Text(
                                          isSettled ? context.tr('settled') : context.tr('pending_due'),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: isSettled ? AppColors.forestMint : AppColors.textSecondary,
                                            fontWeight: FontWeight.w700,
                                          ),
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
