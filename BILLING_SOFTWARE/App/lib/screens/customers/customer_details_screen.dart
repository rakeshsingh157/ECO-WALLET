import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../models/customer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/theme_provider.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  late Customer _customer;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoadingTransactions = false;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _loadTransactions();
  }

  void _loadTransactions() async {
    setState(() => _isLoadingTransactions = true);
    final auth = context.read<AuthProvider>();
    if (auth.apiService.baseUrl.isNotEmpty) {
      final txs = await auth.apiService.getCustomerTransactions(_customer.id);
      if (mounted) {
        setState(() {
          _transactions = txs;
          _isLoadingTransactions = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoadingTransactions = false);
    }
  }

  void _giveCredit() {
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add Credit / Khata Entry',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Giving goods on credit (Udhar) to ${_customer.name}', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              'Current Balance: ₹${_customer.dueAmount.toStringAsFixed(0)}',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.chaiGold),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              decoration: InputDecoration(labelText: 'Credit Amount (₹) *', prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppColors.terracotta)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
              if (amt > 0) {
                final auth = context.read<AuthProvider>();
                await context.read<CustomerProvider>().addCredit(auth.apiService, _customer.id, amt);
                setState(() {
                  _customer.dueAmount = _customer.dueAmount + amt;
                });
                _loadTransactions();
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added ₹${amt.toStringAsFixed(0)} credit for ${_customer.name}'), backgroundColor: AppColors.success),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracotta, foregroundColor: Colors.white),
            child: const Text('SAVE KHATA ENTRY'),
          ),
        ],
      ),
    );
  }

  void _recordPayment() {
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Collect Khata Payment',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Receiving credit payment from ${_customer.name}', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              'Current Balance: ₹${_customer.dueAmount.toStringAsFixed(0)}',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.chaiGold),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              decoration: InputDecoration(labelText: 'Amount Received (₹)', prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppColors.forestMint)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
              if (amt > 0) {
                final auth = context.read<AuthProvider>();
                await context.read<CustomerProvider>().recordPayment(auth.apiService, _customer.id, amt);
                setState(() {
                  _customer.dueAmount = (_customer.dueAmount - amt) < 0 ? 0 : _customer.dueAmount - amt;
                });
                _loadTransactions();
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Received ₹${amt.toStringAsFixed(0)} from ${_customer.name}'), backgroundColor: AppColors.success),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.forestMint, foregroundColor: Colors.white),
            child: const Text('SAVE PAYMENT'),
          ),
        ],
      ),
    );
  }

  void _sendWhatsAppReminder() {
    final message = 'Namaste ${_customer.name}, this is a gentle reminder from Dukaan Dost regarding your pending Khata balance of ₹${_customer.dueAmount.toStringAsFixed(0)}. Kindly clear the dues at your earliest convenience. Thank you!';
    Share.share(message, subject: 'Payment Reminder');
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'CUSTOMER PROFILE',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _customer.name.isNotEmpty ? _customer.name[0].toUpperCase() : 'C',
                        style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.terracotta),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _customer.name,
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  Text(
                    _customer.phone,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  if (_customer.address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          _customer.address,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                  if (_customer.aadhaarNumber.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.forestMint.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.badge_rounded, size: 13, color: AppColors.forestMint),
                          const SizedBox(width: 6),
                          Text(
                            'Aadhaar: ${_customer.aadhaarNumber}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.forestMint),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Divider(color: AppColors.borderSubtle),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(context.tr('total_spent'), style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted)),
                          const SizedBox(height: 2),
                          Text('₹${_customer.totalSpent.toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        ],
                      ),
                      Container(width: 1, height: 28, color: AppColors.borderSubtle),
                      Column(
                        children: [
                          Text(context.tr('purchases'), style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted)),
                          const SizedBox(height: 2),
                          Text('${_customer.totalOrders}', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        ],
                      ),
                      Container(width: 1, height: 28, color: AppColors.borderSubtle),
                      Column(
                        children: [
                          Text(context.tr('pending_due'), style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            '₹${_customer.dueAmount.toStringAsFixed(0)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _customer.dueAmount > 0 ? AppColors.chaiGold : AppColors.forestMint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _giveCredit,
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: const Text('ADD KHATA DUE'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: AppColors.terracotta,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _recordPayment,
                    icon: const Icon(Icons.payments_rounded, size: 18),
                    label: Text(context.tr('collect_due')),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: AppColors.forestMint,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),

            if (_customer.dueAmount > 0) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _sendWhatsAppReminder,
                  icon: Icon(Icons.send_rounded, size: 18, color: AppColors.forestMint),
                  label: Text(
                    'SEND PAYMENT REMINDER',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.forestMint),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: BorderSide(color: AppColors.forestMint),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RECENT TRANSACTIONS',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary),
                      ),
                      if (_isLoadingTransactions)
                        SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.terracotta)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_transactions.isEmpty && !_isLoadingTransactions)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'No transactions recorded yet for this customer.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _transactions.length,
                      separatorBuilder: (_, __) => Divider(color: AppColors.borderSubtle, height: 16),
                      itemBuilder: (ctx, i) {
                        final tx = _transactions[i];
                        final isCredit = tx['type'] == 'credit';
                        final isPayment = tx['type'] == 'payment';
                        final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx['title'] ?? 'Transaction',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tx['subtitle'] ?? (tx['payment_mode'] ?? 'Khata'),
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isCredit ? "+" : isPayment ? "-" : ""}₹${amount.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isCredit ? AppColors.chaiGold : (isPayment ? AppColors.forestMint : AppColors.textPrimary),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
