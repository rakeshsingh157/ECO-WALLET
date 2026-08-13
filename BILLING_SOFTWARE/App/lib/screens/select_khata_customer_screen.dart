import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import 'khata_screen.dart';

class SelectKhataCustomerScreen extends StatefulWidget {
  const SelectKhataCustomerScreen({super.key});

  @override
  State<SelectKhataCustomerScreen> createState() => _SelectKhataCustomerScreenState();
}

class _SelectKhataCustomerScreenState extends State<SelectKhataCustomerScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<KhataCustomer> get filteredCustomers {
    if (_searchQuery.isEmpty) return KhataStore.customers;
    final query = _searchQuery.toLowerCase();
    return KhataStore.customers.where((c) {
      final matchName = c.name.toLowerCase().contains(query);
      final matchPhone = c.phone.toLowerCase().contains(query);
      final matchAadhaar = c.aadhaarNumber?.toLowerCase().contains(query) ?? false;
      return matchName || matchPhone || matchAadhaar;
    }).toList();
  }

  void _showAddKhataDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final aadhaarCtrl = TextEditingController();
    final amountCtrl = TextEditingController(text: '0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Khata Customer',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.warmPeach),
            ),
            const SizedBox(height: 4),
            Text(
              'Record customer details & optional Aadhaar / photo.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Customer Name *', prefixIcon: Icon(Icons.person_rounded, color: AppColors.warmCoral)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number *', prefixIcon: Icon(Icons.phone_rounded, color: AppColors.warmCoral)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(labelText: 'Address (Optional)', prefixIcon: Icon(Icons.home_rounded, color: AppColors.warmCoral)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: aadhaarCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Aadhaar Card Number (Optional)', hintText: '12-digit Aadhaar', prefixIcon: Icon(Icons.badge_rounded, color: AppColors.warmCoral)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Initial Due Amount (₹)', prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppColors.warmCoral)),
            ),
            const SizedBox(height: 20),

            GradientButton(
              text: 'Save Khata Customer',
              icon: Icons.person_add_rounded,
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                  final newCustomer = KhataCustomer(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null,
                    aadhaarNumber: aadhaarCtrl.text.trim().isNotEmpty ? aadhaarCtrl.text.trim() : null,
                    dueAmount: double.tryParse(amountCtrl.text) ?? 0.0,
                    lastTransaction: DateTime.now(),
                  );
                  setState(() {
                    KhataStore.customers.insert(0, newCustomer);
                  });
                  Navigator.pop(ctx);
                  // Auto-select newly created customer
                  Navigator.pop(context, newCustomer);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Khata Customer',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: AppColors.warmCoral),
            onPressed: _showAddKhataDialog,
            tooltip: 'Add Customer',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _searchController,
              onChanged: (q) => setState(() => _searchQuery = q),
              decoration: InputDecoration(
                hintText: 'Search by Name, Phone or Aadhaar...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.warmCoral),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Customers List
          Expanded(
            child: filteredCustomers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_search_rounded, size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No Khata customer found',
                          style: GoogleFonts.inter(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _showAddKhataDialog,
                          icon: const Icon(Icons.add_rounded, color: AppColors.warmCoral),
                          label: Text(
                            'Add New Customer',
                            style: GoogleFonts.poppins(color: AppColors.warmCoral, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.warmCoral),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];

                      return GestureDetector(
                        onTap: () {
                          // Return selected customer to CheckoutScreen
                          Navigator.pop(context, customer);
                        },
                        child: Container(
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
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.warmCoral.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    customer.name[0],
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.warmCoral,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customer.name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${customer.phone}${customer.address != null ? ' • ${customer.address}' : ''}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    if (customer.aadhaarNumber != null)
                                      Text(
                                        'Aadhaar: ${customer.aadhaarNumber}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
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
                                    '₹${customer.dueAmount.toStringAsFixed(0)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                  Text(
                                    'Due Balance',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AppColors.warning,
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
    );
  }
}
