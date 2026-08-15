import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../models/customer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/theme_provider.dart';

class CustomerPickerScreen extends StatefulWidget {
  final Customer? selectedCustomer;

  const CustomerPickerScreen({super.key, this.selectedCustomer});

  @override
  State<CustomerPickerScreen> createState() => _CustomerPickerScreenState();
}

class _CustomerPickerScreenState extends State<CustomerPickerScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddNewCustomer() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final aadhaarCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
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
                    ctx.tr('add_customer'),
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              TextField(
                controller: nameCtrl,
                style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                decoration: InputDecoration(labelText: ctx.tr('customer_name'), prefixIcon: Icon(Icons.person_rounded, color: AppColors.terracotta)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
                decoration: InputDecoration(labelText: ctx.tr('customer_phone'), prefixIcon: Icon(Icons.phone_rounded, color: AppColors.terracotta)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
                decoration: InputDecoration(labelText: ctx.tr('customer_address_optional'), prefixIcon: Icon(Icons.location_on_rounded, color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isNotEmpty && phoneCtrl.text.trim().isNotEmpty) {
                      final auth = context.read<AuthProvider>();
                      final newCust = Customer(
                        id: 'cust_${DateTime.now().millisecondsSinceEpoch}',
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        address: addressCtrl.text.trim(),
                        aadhaarNumber: aadhaarCtrl.text.trim(),
                      );
                      await context.read<CustomerProvider>().addCustomer(auth.apiService, newCust);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                      if (mounted) {
                        Navigator.pop(context, newCust);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(ctx.tr('save_customer')),
                ),
              ),
            ],
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

    final filtered = allCustomers.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final matchesName = c.name.toLowerCase().contains(q);
      final matchesPhone = c.phone.toLowerCase().contains(q);
      final matchesAddress = c.address.toLowerCase().contains(q);
      final matchesAadhaar = c.aadhaarNumber.toLowerCase().contains(q);
      return matchesName || matchesPhone || matchesAddress || matchesAadhaar;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          context.tr('select_customer').toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_alt_1_rounded, color: AppColors.terracotta),
            onPressed: _showAddNewCustomer,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: AppColors.surface,
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: context.tr('search_customer'),
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: AppColors.textSecondary),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filtered.length} ${filtered.length == 1 ? "Customer" : "Customers"} found',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    InkWell(
                      onTap: _showAddNewCustomer,
                      child: Text(
                        '+ Add New Customer',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.terracotta),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: AppColors.borderSubtle, height: 1),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off_rounded, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No customers matching "$_searchQuery"',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _showAddNewCustomer,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('CREATE NEW CUSTOMER'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.terracotta,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final customer = filtered[i];
                      final isSelected = widget.selectedCustomer?.id == customer.id;

                      return InkWell(
                        onTap: () => Navigator.pop(context, customer),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.terracotta.withAlpha(20) : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppColors.terracotta : AppColors.borderSubtle,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.terracotta),
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
                                            customer.name,
                                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(width: 6),
                                          Icon(Icons.check_circle_rounded, size: 16, color: AppColors.terracotta),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      customer.phone,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                    if (customer.address.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on_rounded, size: 11, color: AppColors.textMuted),
                                          const SizedBox(width: 3),
                                          Expanded(
                                            child: Text(
                                              customer.address,
                                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (customer.aadhaarNumber.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.forestMint.withAlpha(25),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Aadhaar: ${customer.aadhaarNumber}',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.forestMint),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (customer.dueAmount > 0) ...[
                                    Text(
                                      'Due: ₹${customer.dueAmount.toStringAsFixed(0)}',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.chaiGold),
                                    ),
                                  ] else ...[
                                    Text(
                                      'No Due',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.forestMint),
                                    ),
                                  ],
                                  const SizedBox(height: 2),
                                  Text(
                                    '${customer.totalOrders} ${customer.totalOrders == 1 ? "order" : "orders"}',
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
    );
  }
}
