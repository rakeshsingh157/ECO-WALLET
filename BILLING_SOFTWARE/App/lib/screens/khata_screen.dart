import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/api_service.dart';
import '../providers/auth_provider.dart';

class KhataCustomer {
  final String id;
  final String name;
  final String phone;
  final String? address;
  final String? aadhaarNumber;
  final String? photoUrl;
  double dueAmount;
  final DateTime lastTransaction;

  KhataCustomer({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    this.aadhaarNumber,
    this.photoUrl,
    required this.dueAmount,
    required this.lastTransaction,
  });
}

class KhataStore {
  static final List<KhataCustomer> customers = [];
}

class KhataScreen extends StatefulWidget {
  const KhataScreen({super.key});

  @override
  State<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends State<KhataScreen> {
  bool _isLoading = false;

  double get totalDue => KhataStore.customers.fold(0, (sum, c) => sum + c.dueAmount);

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  void _fetchCustomers() async {
    final auth = context.read<AuthProvider>();
    final targetBase = auth.baseUrl.isNotEmpty ? auth.baseUrl : AppConstants.defaultEcoWalletBaseUrl;
    final apiService = ApiService(baseUrl: targetBase, apiKey: auth.apiKey);

    setState(() => _isLoading = true);
    final list = await apiService.getKhataCustomers();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (list.isNotEmpty) {
          KhataStore.customers.clear();
          for (var item in list) {
            KhataStore.customers.add(
              KhataCustomer(
                id: item['customer_id'] ?? item['_id'] ?? '',
                name: item['name'] ?? 'Customer',
                phone: item['phone'] ?? '',
                address: item['address'],
                aadhaarNumber: item['aadhaar_number'],
                dueAmount: (item['due_amount'] as num?)?.toDouble() ?? 0.0,
                lastTransaction: item['updatedAt'] != null ? DateTime.tryParse(item['updatedAt']) ?? DateTime.now() : DateTime.now(),
              ),
            );
          }
        }
      });
    }
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
              'Customer details are saved directly to MongoDB Atlas.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),

            // Name
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Customer Name *', prefixIcon: Icon(Icons.person_rounded, color: AppColors.warmCoral)),
            ),
            const SizedBox(height: 12),

            // Phone
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number *', prefixIcon: Icon(Icons.phone_rounded, color: AppColors.warmCoral)),
            ),
            const SizedBox(height: 12),

            // Address (Optional)
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(labelText: 'Address (Optional)', prefixIcon: Icon(Icons.home_rounded, color: AppColors.warmCoral)),
            ),
            const SizedBox(height: 12),

            // Aadhaar Number (Optional)
            TextField(
              controller: aadhaarCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Aadhaar Card Number (Optional)', hintText: '12-digit Aadhaar', prefixIcon: Icon(Icons.badge_rounded, color: AppColors.warmCoral)),
            ),
            const SizedBox(height: 12),

            // Initial Due Amount
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Initial Due Amount (₹)', prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppColors.warmCoral)),
            ),

            const SizedBox(height: 20),

            GradientButton(
              text: 'Save Khata Customer',
              icon: Icons.person_add_rounded,
              onPressed: () async {
                if (nameCtrl.text.trim().isNotEmpty && phoneCtrl.text.trim().isNotEmpty) {
                  final auth = context.read<AuthProvider>();
                  final targetBase = auth.baseUrl.isNotEmpty ? auth.baseUrl : AppConstants.defaultEcoWalletBaseUrl;
                  final apiService = ApiService(baseUrl: targetBase, apiKey: auth.apiKey);
                  final custId = 'k_${DateTime.now().millisecondsSinceEpoch}';

                  final newCustomer = KhataCustomer(
                    id: custId,
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

                  await apiService.addKhataCustomer(
                    customerId: custId,
                    name: newCustomer.name,
                    phone: newCustomer.phone,
                    address: newCustomer.address,
                    aadhaarNumber: newCustomer.aadhaarNumber,
                    dueAmount: newCustomer.dueAmount,
                  );

                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${newCustomer.name} saved to Khata Book!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
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
        title: Row(
          children: [
            const Icon(Icons.menu_book_rounded, color: AppColors.warmCoral, size: 24),
            const SizedBox(width: 10),
            Text(
              'Khata Book',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _fetchCustomers,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.warmCoral))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Pending Khata Card
                  GlassCard(
                    padding: const EdgeInsets.all(22),
                    borderRadius: 22,
                    color: AppColors.warning.withValues(alpha: 0.15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Pending Khata',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warning),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '₹${totalDue.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.warning),
                            ),
                            Text(
                              'From ${KhataStore.customers.length} Customers',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.menu_book_rounded, color: AppColors.warning, size: 32),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Customer Dues List',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddKhataDialog,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Customer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warmCoral,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  if (KhataStore.customers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(30),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(Icons.menu_book_rounded, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 10),
                          Text('No Khata Customers Yet', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          Text('Add customer records to track credit and pending dues.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    )
                  else
                    ...KhataStore.customers.map((c) => Container(
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
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.warmCoral.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.warmCoral),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.name, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    Text('${c.phone}${c.address != null ? ' • ${c.address}' : ''}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                                    if (c.aadhaarNumber != null)
                                      Text('Aadhaar: ${c.aadhaarNumber}', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('₹${c.dueAmount.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.warning)),
                                  Text('Pending', style: GoogleFonts.inter(fontSize: 11, color: AppColors.warning)),
                                ],
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}
