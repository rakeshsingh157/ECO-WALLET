import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/app_notifier.dart';
import '../../core/localization.dart';
import '../../models/customer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/bill_provider.dart';
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
    final customerProvider = context.read<CustomerProvider>();
    final liveCustomer = customerProvider.customers.firstWhere(
      (c) => c.id == _customer.id || c.phone == _customer.phone,
      orElse: () => _customer,
    );
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController(text: 'Store goods on credit');
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
                              color: AppColors.terracotta.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.add_card_rounded, size: 20, color: AppColors.terracotta),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            context.tr('add_credit_entry').toUpperCase(),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Current Khata Due',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '₹${liveCustomer.dueAmount.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppColors.chaiGold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'Credit Amount (₹) *',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        TextField(
                          controller: amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.terracotta,
                          ),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppColors.terracotta, size: 20),
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
                            'Reason / Particulars (Optional)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        TextField(
                          controller: noteCtrl,
                          style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Store goods, groceries, etc.',
                            prefixIcon: Icon(Icons.notes_rounded, color: AppColors.textSecondary, size: 20),
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
                              final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                              if (amt <= 0) {
                                AppNotifier.warning(ctx, 'Please enter a valid credit amount', title: 'INVALID AMOUNT');
                                return;
                              }

                              setModalState(() => isSaving = true);
                              try {
                                final auth = context.read<AuthProvider>();
                                final note = noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : 'Store goods credit';
                                await context.read<CustomerProvider>().addCredit(
                                  auth.apiService,
                                  liveCustomer.id,
                                  amt,
                                  note: note,
                                );
                                _loadTransactions();
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                if (mounted) {
                                  AppNotifier.success(
                                    context,
                                    'Added ₹${amt.toStringAsFixed(0)} credit for ${liveCustomer.name}',
                                    title: 'KHATA UPDATED',
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
                        isSaving ? 'SAVING CREDIT...' : 'RECORD KHATA CREDIT',
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

  void _recordPayment() {
    final customerProvider = context.read<CustomerProvider>();
    final liveCustomer = customerProvider.customers.firstWhere(
      (c) => c.id == _customer.id || c.phone == _customer.phone,
      orElse: () => _customer,
    );

    if (liveCustomer.dueAmount <= 0) {
      AppNotifier.info(
        context,
        '${liveCustomer.name} has no outstanding pending dues',
        title: 'NO DUES',
      );
      return;
    }

    final amountCtrl = TextEditingController(text: liveCustomer.dueAmount > 0 ? liveCustomer.dueAmount.toStringAsFixed(0) : '');
    final noteCtrl = TextEditingController(text: 'Khata settlement');
    String selectedMode = 'cash';
    bool isRecording = false;

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
                              color: AppColors.forestMint.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.payments_rounded, size: 20, color: AppColors.forestMint),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            context.tr('collect_due').toUpperCase(),
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
                        onPressed: isRecording ? null : () => Navigator.pop(ctx),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.tr('max_payable_due'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '₹${liveCustomer.dueAmount.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.chaiGold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'Amount Received (₹) *',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        TextField(
                          controller: amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forestMint,
                          ),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppColors.forestMint, size: 20),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 8,
                          children: [
                            ActionChip(
                              label: const Text('Full Due'),
                              labelStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.chaiGold,
                              ),
                              backgroundColor: AppColors.chaiGold.withValues(alpha: 0.15),
                              side: BorderSide.none,
                              onPressed: () {
                                amountCtrl.text = liveCustomer.dueAmount.toStringAsFixed(0);
                              },
                            ),
                            ...[100, 200, 500, 1000].map((preset) {
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
                            }),
                          ],
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
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Payment Mode',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          children: ['cash', 'upi', 'bank'].map((mode) {
                            final isSel = selectedMode == mode;
                            return ChoiceChip(
                              label: Text(
                                mode == 'cash'
                                    ? context.tr('cash')
                                    : (mode == 'upi' ? context.tr('upi') : context.tr('bank')),
                              ),
                              selected: isSel,
                              selectedColor: AppColors.forestMint,
                              labelStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                color: isSel ? Colors.white : AppColors.textPrimary,
                              ),
                              backgroundColor: isDark ? const Color(0xFF243042) : const Color(0xFFEBE6DC),
                              showCheckmark: false,
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              onSelected: isRecording ? null : (_) => setModalState(() => selectedMode = mode),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 14),

                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'Note / Memo (Optional)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        TextField(
                          controller: noteCtrl,
                          style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'e.g. Khata settlement',
                            prefixIcon: Icon(Icons.notes_rounded, color: AppColors.textSecondary, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isRecording
                          ? null
                          : () async {
                              final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                              if (amt <= 0) {
                                AppNotifier.warning(ctx, 'Please enter a valid payment amount', title: 'INVALID AMOUNT');
                                return;
                              }

                              if (amt > _customer.dueAmount) {
                                AppNotifier.warning(
                                  ctx,
                                  'Payment amount (₹${amt.toStringAsFixed(0)}) cannot exceed pending due of ₹${_customer.dueAmount.toStringAsFixed(0)}',
                                  title: 'EXCEEDS DUE AMOUNT',
                                );
                                return;
                              }

                              setModalState(() => isRecording = true);
                              final auth = context.read<AuthProvider>();
                              final custProvider = context.read<CustomerProvider>();
                              final billProvider = context.read<BillProvider>();
                              final note = noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : 'Khata settlement';

                              final success = await custProvider.recordPayment(
                                auth.apiService,
                                _customer.id,
                                amt,
                                note: note,
                                paymentMode: selectedMode,
                              );

                              if (success) {
                                setState(() {
                                  _customer.dueAmount = (_customer.dueAmount - amt) < 0 ? 0 : _customer.dueAmount - amt;
                                });
                                _loadTransactions();
                                billProvider.fetchBills(auth.apiService);
                                custProvider.fetchCustomers(auth.apiService);
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                if (mounted) {
                                  AppNotifier.success(
                                    context,
                                    'Received ₹${amt.toStringAsFixed(0)} from ${_customer.name} via ${selectedMode.toUpperCase()}',
                                    title: 'PAYMENT RECORDED',
                                  );
                                }
                              } else {
                                setModalState(() => isRecording = false);
                                if (ctx.mounted) {
                                  AppNotifier.error(ctx, 'Failed to record payment. Please try again.', title: 'PAYMENT ERROR');
                                }
                              }
                            },
                      icon: isRecording
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_rounded, size: 20),
                      label: Text(
                        isRecording ? 'SAVING PAYMENT...' : 'CONFIRM & SAVE PAYMENT',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forestMint,
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

  void _sendWhatsAppReminder() {
    final message = 'Namaste ${_customer.name}, this is a gentle reminder from Dukaan Dost regarding your pending Khata balance of ₹${_customer.dueAmount.toStringAsFixed(0)}. Kindly clear the dues at your earliest convenience. Thank you!';
    Share.share(message, subject: 'Payment Reminder');
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final liveCustomer = customerProvider.customers.firstWhere(
      (c) => c.id == _customer.id || c.phone == _customer.phone,
      orElse: () => _customer,
    );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          context.tr('customers').toUpperCase(),
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
                        liveCustomer.name.isNotEmpty ? liveCustomer.name[0].toUpperCase() : 'C',
                        style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.terracotta),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    liveCustomer.name,
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  Text(
                    liveCustomer.phone,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  if (liveCustomer.address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          liveCustomer.address,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                  if (liveCustomer.aadhaarNumber.isNotEmpty) ...[
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
                            '${context.tr('aadhaar_number')}: ${liveCustomer.aadhaarNumber}',
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
                          Text('₹${liveCustomer.totalSpent.toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        ],
                      ),
                      Container(width: 1, height: 28, color: AppColors.borderSubtle),
                      Column(
                        children: [
                          Text(context.tr('purchases'), style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted)),
                          const SizedBox(height: 2),
                          Text('${liveCustomer.totalOrders}', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        ],
                      ),
                      Container(width: 1, height: 28, color: AppColors.borderSubtle),
                      Column(
                        children: [
                          Text(context.tr('pending_due'), style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            '₹${liveCustomer.dueAmount.toStringAsFixed(0)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: liveCustomer.dueAmount > 0 ? AppColors.chaiGold : AppColors.forestMint,
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
                    label: Text(context.tr('give_credit')),
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

            if (liveCustomer.dueAmount > 0) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _sendWhatsAppReminder,
                  icon: Icon(Icons.send_rounded, size: 18, color: AppColors.forestMint),
                  label: Text(
                    context.tr('reminder').toUpperCase(),
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
                        context.tr('khata_transaction_history').toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.textSecondary),
                      ),
                      if (_isLoadingTransactions)
                        SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.terracotta))
                      else
                        Text(
                          '${_transactions.length} ${context.tr('records')}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_transactions.isEmpty && !_isLoadingTransactions)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          context.tr('no_transactions_customer'),
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
                        final balanceAfter = (tx['balance_after'] as num?)?.toDouble();

                        String formattedDate = '';
                        if (tx['date'] != null) {
                          final parsedDate = DateTime.tryParse(tx['date'])?.toLocal();
                          if (parsedDate != null) {
                            formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(parsedDate);
                          }
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isPayment
                                    ? AppColors.forestMint.withAlpha(25)
                                    : (isCredit ? AppColors.chaiGold.withAlpha(25) : AppColors.primaryContainer),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isPayment
                                    ? Icons.arrow_downward_rounded
                                    : (isCredit ? Icons.arrow_upward_rounded : Icons.receipt_long_rounded),
                                color: isPayment ? AppColors.forestMint : (isCredit ? AppColors.chaiGold : AppColors.terracotta),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        tx['title'] ?? 'Transaction',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isPayment
                                              ? AppColors.forestMint.withAlpha(30)
                                              : (isCredit ? AppColors.chaiGold.withAlpha(30) : AppColors.secondaryContainer),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          (tx['payment_mode'] ?? (isCredit ? 'KHATA' : 'CASH')).toString().toUpperCase(),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: isPayment ? AppColors.forestMint : (isCredit ? AppColors.chaiGold : AppColors.textSecondary),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tx['subtitle'] ?? '',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                  if (formattedDate.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      formattedDate,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textMuted),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isCredit ? "+" : isPayment ? "-" : ""}₹${amount.toStringAsFixed(0)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: isCredit ? AppColors.chaiGold : (isPayment ? AppColors.forestMint : AppColors.textPrimary),
                                  ),
                                ),
                                if (balanceAfter != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '${context.tr('balance')}: ₹${balanceAfter.toStringAsFixed(0)}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                                  ),
                                ],
                              ],
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
