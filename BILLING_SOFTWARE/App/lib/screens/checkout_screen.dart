import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/bill_provider.dart';
import '../models/bill.dart';
import '../widgets/bill_item_tile.dart';
import 'bill_success_screen.dart';
import 'khata_screen.dart';
import 'select_khata_customer_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PaymentMode _selectedMode = PaymentMode.ecoWallet;
  KhataCustomer? _selectedKhataCustomer;

  @override
  void initState() {
    super.initState();
    if (KhataStore.customers.isNotEmpty) {
      _selectedKhataCustomer = KhataStore.customers.first;
    }
    // Auto-generate ECO QR code & start background session immediately!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedMode == PaymentMode.ecoWallet) {
        _autoStartEcoPayment();
      }
    });
  }

  @override
  void dispose() {
    // Terminate active session & cancel all timers when screen closes
    context.read<BillProvider>().stopPolling();
    super.dispose();
  }

  void _autoStartEcoPayment() async {
    final billProvider = context.read<BillProvider>();
    final auth = context.read<AuthProvider>();

    if (billProvider.activeQrData != null || billProvider.isCreatingPayment) return;

    final apiService = ApiService(
      baseUrl: auth.baseUrl,
      apiKey: auth.apiKey,
    );

    final success = await billProvider.initiateEcoPayment(apiService);
    if (success && mounted) {
      billProvider.startStatusPolling(
        apiService,
        onSuccess: (completedBill) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => BillSuccessScreen(bill: completedBill),
              ),
            );
          }
        },
      );
    }
  }

  void _openCustomerSearch() async {
    final selected = await Navigator.push<KhataCustomer>(
      context,
      MaterialPageRoute(builder: (_) => const SelectKhataCustomerScreen()),
    );

    if (selected != null) {
      setState(() {
        _selectedKhataCustomer = selected;
        _selectedMode = PaymentMode.pending;
      });
    }
  }

  void _processPayment() async {
    final billProvider = context.read<BillProvider>();

    if (_selectedMode == PaymentMode.ecoWallet) {
      // Re-trigger auto start if needed
      _autoStartEcoPayment();
    } else if (_selectedMode == PaymentMode.pending) {
      // Khata Payment
      if (_selectedKhataCustomer == null) {
        _openCustomerSearch();
        return;
      }

      // Add to Khata customer's due amount
      _selectedKhataCustomer!.dueAmount += billProvider.currentTotal;

      final bill = billProvider.completeManualBill(
        PaymentMode.pending,
        customerName: '${_selectedKhataCustomer!.name} (Khata)',
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BillSuccessScreen(bill: bill),
          ),
        );
      }
    } else {
      // Manual Cash or UPI payment
      final bill = billProvider.completeManualBill(_selectedMode);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BillSuccessScreen(bill: bill),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = context.watch<BillProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Checkout Payment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bill Summary Header
            GlassCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Payable',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        '₹${billProvider.currentTotal.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.warmPeach,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.warmCoral.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${billProvider.itemCount} Items',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warmCoral,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Select Payment Method Header
            Text(
              'Select Payment Method',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),

            // 4 Payment Mode Selector Cards (ECO, Cash, UPI, Khata)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentMethodCard(
                        mode: PaymentMode.ecoWallet,
                        title: 'ECO Wallet',
                        subtitle: 'QR Payment',
                        icon: Icons.stars_rounded,
                        accentColor: AppColors.warmPeach,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPaymentMethodCard(
                        mode: PaymentMode.cash,
                        title: 'Cash',
                        subtitle: 'Counter Cash',
                        icon: Icons.payments_rounded,
                        accentColor: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentMethodCard(
                        mode: PaymentMode.upi,
                        title: 'UPI',
                        subtitle: 'GPay/PhonePe',
                        icon: Icons.qr_code_rounded,
                        accentColor: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPaymentMethodCard(
                        mode: PaymentMode.pending,
                        title: 'Khata Credit',
                        subtitle: 'Book Dues',
                        icon: Icons.menu_book_rounded,
                        accentColor: AppColors.warning,
                        onTapOverride: () {
                          setState(() => _selectedMode = PaymentMode.pending);
                          _openCustomerSearch();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Dedicated Khata Customer Selection Tile
            if (_selectedMode == PaymentMode.pending) ...[
              GlassCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 20,
                color: AppColors.darkCard.withValues(alpha: 0.95),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Selected Khata Customer',
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.warning),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _openCustomerSearch,
                          icon: const Icon(Icons.search_rounded, size: 16, color: AppColors.warmCoral),
                          label: Text(
                            'Search / Change',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warmCoral),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_selectedKhataCustomer != null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _selectedKhataCustomer!.name[0],
                                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.warning),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_selectedKhataCustomer!.name, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                  Text(_selectedKhataCustomer!.phone, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₹${_selectedKhataCustomer!.dueAmount.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.warning)),
                                Text('Current Due', style: GoogleFonts.inter(fontSize: 10, color: AppColors.warning)),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _openCustomerSearch,
                        icon: const Icon(Icons.person_search_rounded, color: AppColors.warning),
                        label: const Text('Tap to Select Khata Customer'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: const BorderSide(color: AppColors.warning),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ECO Wallet QR Display Area
            if (_selectedMode == PaymentMode.ecoWallet) ...[
              GlassCard(
                padding: const EdgeInsets.all(24),
                borderRadius: 24,
                color: AppColors.darkCard.withValues(alpha: 0.95),
                child: Column(
                  children: [
                    Text(
                      'Customer Scan & Pay',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warmPeach,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customer scans QR using ECO Wallet App',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (billProvider.isCreatingPayment) ...[
                      const CircularProgressIndicator(color: AppColors.warmCoral),
                      const SizedBox(height: 16),
                      Text(
                        'Generating ECO Merchant Payment QR...',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ] else if (billProvider.activeQrData != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, size: 14, color: AppColors.error),
                            const SizedBox(width: 6),
                            Text(
                              'Expires in ${billProvider.formattedCountdown}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: QrImageView(
                          data: billProvider.activeQrData!,
                          version: QrVersions.auto,
                          size: 200.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.warmCoral,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Listening for live payment...',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warmCoral,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Icon(Icons.qr_code_2_rounded, size: 80, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'Click below to generate QR',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],

                    if (billProvider.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        billProvider.errorMessage!,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.error),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Itemized Bill Summary
            Text(
              'Items in Bill',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            ...billProvider.currentItems.map(
              (item) => BillItemTile(
                item: item,
                onAdd: () => billProvider.addItem(item.product),
                onRemove: () => billProvider.removeItem(item.product),
              ),
            ),

            const SizedBox(height: 30),

            // Action Button
            GradientButton(
              text: _selectedMode == PaymentMode.ecoWallet
                  ? (billProvider.activeQrData == null ? 'Generate ECO QR Code' : 'Payment Pending...')
                  : (_selectedMode == PaymentMode.pending ? 'Add to ${_selectedKhataCustomer?.name ?? 'Khata'}' : 'Complete ${_selectedMode == PaymentMode.cash ? 'Cash' : 'UPI'} Payment'),
              icon: _selectedMode == PaymentMode.ecoWallet
                  ? Icons.qr_code_rounded
                  : (_selectedMode == PaymentMode.pending ? Icons.menu_book_rounded : Icons.check_circle_rounded),
              isLoading: billProvider.isCreatingPayment,
              onPressed: billProvider.activeQrData != null && _selectedMode == PaymentMode.ecoWallet
                  ? null
                  : _processPayment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required PaymentMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    VoidCallback? onTapOverride,
  }) {
    final isSelected = _selectedMode == mode;

    return GestureDetector(
      onTap: onTapOverride ?? () => setState(() => _selectedMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.15) : AppColors.darkCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.glassBorder.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? accentColor : AppColors.textMuted, size: 26),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? accentColor : AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
