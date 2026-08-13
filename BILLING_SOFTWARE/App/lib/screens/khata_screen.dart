import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';

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
  static final List<KhataCustomer> customers = [
    KhataCustomer(id: '1', name: 'Ramesh Kumar', phone: '+91 98765 43210', address: 'Shop 4, Main Market', aadhaarNumber: '1234 5678 9012', dueAmount: 450.0, lastTransaction: DateTime.now().subtract(const Duration(hours: 2))),
    KhataCustomer(id: '2', name: 'Suresh Sharma', phone: '+91 98123 45678', address: 'Block B, Sector 5', aadhaarNumber: '9876 5432 1098', dueAmount: 1200.0, lastTransaction: DateTime.now().subtract(const Duration(days: 1))),
    KhataCustomer(id: '3', name: 'Anita Verma', phone: '+91 97111 22334', address: 'House 12, Gandhi Nagar', aadhaarNumber: '4567 8901 2345', dueAmount: 650.0, lastTransaction: DateTime.now().subtract(const Duration(days: 2))),
    KhataCustomer(id: '4', name: 'Vikram Singh', phone: '+91 96555 88990', address: 'Station Road', dueAmount: 2400.0, lastTransaction: DateTime.now().subtract(const Duration(days: 3))),
    KhataCustomer(id: '5', name: 'Pooja Gupta', phone: '+91 95444 33221', dueAmount: 850.0, lastTransaction: DateTime.now().subtract(const Duration(days: 4))),
  ];
}

class KhataScreen extends StatefulWidget {
  const KhataScreen({super.key});

  @override
  State<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends State<KhataScreen> {
  double get totalDue => KhataStore.customers.fold(0, (sum, c) => sum + c.dueAmount);

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
              'Record customer details & optional Aadhaar / photo for trust records.',
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
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                  setState(() {
                    KhataStore.customers.insert(
                      0,
                      KhataCustomer(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null,
                        aadhaarNumber: aadhaarCtrl.text.trim().isNotEmpty ? aadhaarCtrl.text.trim() : null,
                        dueAmount: double.tryParse(amountCtrl.text) ?? 0.0,
                        lastTransaction: DateTime.now(),
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${nameCtrl.text} added to Khata Book!')),
                  );
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
      ),
      body: SingleChildScrollView(
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
                            c.name[0],
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
