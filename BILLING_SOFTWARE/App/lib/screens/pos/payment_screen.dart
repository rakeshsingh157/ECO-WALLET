import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../core/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bill_provider.dart';
import '../../providers/customer_provider.dart';
import '../../models/bill.dart';
import '../../models/customer.dart';
import 'bill_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMode _selectedMode = PaymentMode.cash;
  Customer? _selectedCustomer;
  double _cashTendered = 0.0;

  @override
  void initState() {
    super.initState();
    final customers = context.read<CustomerProvider>().customers;
    if (customers.isNotEmpty) {
      _selectedCustomer = customers.first;
    }
  }

  void _autoStartEcoPayment() async {
    final billProvider = context.read<BillProvider>();
    final auth = context.read<AuthProvider>();

    if (billProvider.activeQrData != null || billProvider.isCreatingPayment) return;

    final apiService = ApiService(baseUrl: auth.baseUrl, apiKey: auth.apiKey);
    final success = await billProvider.initiateEcoPayment(
      apiService,
      merchantId: auth.merchantId.isNotEmpty ? auth.merchantId : (auth.mobileNumber.isNotEmpty ? 'mch_${auth.mobileNumber}' : null),
      shopName: auth.shopName.isNotEmpty ? auth.shopName : null,
      ownerName: auth.ownerName.isNotEmpty ? auth.ownerName : null,
    );

    if (success && mounted) {
      billProvider.startStatusPolling(
        apiService,
        onSuccess: (completedBill) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => BillSuccessScreen(bill: completedBill)),
            );
          }
        },
      );
    }
  }

  void _processPayment() {
    final billProvider = context.read<BillProvider>();
    final auth = context.read<AuthProvider>();
    final apiService = ApiService(baseUrl: auth.baseUrl, apiKey: auth.apiKey);

    if (_selectedMode == PaymentMode.ecoWallet) {
      _autoStartEcoPayment();
    } else if (_selectedMode == PaymentMode.pending) {
      if (_selectedCustomer != null) {
        context.read<CustomerProvider>().addCredit(apiService, _selectedCustomer!.id, billProvider.currentTotal);
      }
      final bill = billProvider.completeManualBill(
        PaymentMode.pending,
        customerName: _selectedCustomer != null ? '${_selectedCustomer!.name} (Khata)' : 'Khata Customer',
        apiService: apiService,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BillSuccessScreen(bill: bill)),
      );
    } else {
      final bill = billProvider.completeManualBill(
        _selectedMode,
        customerName: _selectedCustomer?.name,
        apiService: apiService,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BillSuccessScreen(bill: bill)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = context.watch<BillProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final changeDue = _cashTendered > billProvider.currentTotal ? _cashTendered - billProvider.currentTotal : 0.0;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          context.tr('collect_payment').toUpperCase(),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('grand_total').toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${billProvider.currentTotal.toStringAsFixed(0)}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.terracotta),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${billProvider.itemCount} Items',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.terracotta),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              context.tr('payment_mode'),
              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildModeCard(
                    mode: PaymentMode.cash,
                    title: context.tr('cash'),
                    subtitle: 'Drawer',
                    icon: Icons.payments_rounded,
                    color: AppColors.forestMint,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildModeCard(
                    mode: PaymentMode.ecoWallet,
                    title: context.tr('eco_wallet'),
                    subtitle: 'Dynamic QR',
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppColors.terracotta,
                    onTap: () {
                      setState(() => _selectedMode = PaymentMode.ecoWallet);
                      _autoStartEcoPayment();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildModeCard(
                    mode: PaymentMode.upi,
                    title: context.tr('upi'),
                    subtitle: 'GPay/PhonePe',
                    icon: Icons.qr_code_rounded,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildModeCard(
                    mode: PaymentMode.pending,
                    title: context.tr('khata_credit'),
                    subtitle: 'Credit Book',
                    icon: Icons.menu_book_rounded,
                    color: AppColors.chaiGold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (_selectedMode == PaymentMode.cash) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('cash_received').toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildCashChip('Exact (₹${billProvider.currentTotal.toStringAsFixed(0)})', billProvider.currentTotal),
                        _buildCashChip('₹100', 100),
                        _buildCashChip('₹200', 200),
                        _buildCashChip('₹500', 500),
                        _buildCashChip('₹2000', 2000),
                      ],
                    ),
                    if (_cashTendered > 0) ...[
                      const SizedBox(height: 12),
                      Divider(color: AppColors.borderSubtle),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${context.tr('change_return')}:', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          Text(
                            '₹${changeDue.toStringAsFixed(0)}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.forestMint),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (_selectedMode == PaymentMode.pending) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.chaiGold.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('customers').toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.chaiGold),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<Customer>(
                      initialValue: _selectedCustomer,
                      decoration: InputDecoration(
                        labelText: context.tr('search_customer'),
                        prefixIcon: Icon(Icons.person_rounded, color: AppColors.chaiGold),
                      ),
                      items: customerProvider.customers
                          .map((c) => DropdownMenuItem(value: c, child: Text('${c.name} (${c.phone})', style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary))))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCustomer = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (_selectedMode == PaymentMode.ecoWallet && billProvider.activeQrData != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.terracotta.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'SCAN TO PAY VIA ECO WALLET',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.terracotta),
                    ),
                    const SizedBox(height: 14),
                    QrImageView(
                      data: billProvider.activeQrData!,
                      version: QrVersions.auto,
                      size: 180.0,
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.textPrimary,
                      ),
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Listening for instant payment confirmation...',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.terracotta),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _processPayment,
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: Text(context.tr('pay_now').toUpperCase()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.terracotta,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCashChip(String label, double amount) {
    final isSelected = _cashTendered == amount;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _cashTendered = amount),
      selectedColor: AppColors.secondaryContainer,
      backgroundColor: AppColors.surface,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isSelected ? AppColors.forestMint : AppColors.textPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isSelected ? AppColors.forestMint : AppColors.borderSubtle),
      ),
    );
  }

  Widget _buildModeCard({
    required PaymentMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedMode == mode;

    return InkWell(
      onTap: onTap ?? () => setState(() => _selectedMode = mode),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppColors.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : AppColors.textSecondary, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? color : AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
