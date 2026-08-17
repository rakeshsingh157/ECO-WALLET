import 'dart:async';
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
import '../../providers/theme_provider.dart';
import '../../models/bill.dart';
import '../../models/customer.dart';
import '../customers/customer_picker_screen.dart';
import '../settings/shop_profile_screen.dart';
import 'bill_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMode _selectedMode = PaymentMode.cash;
  Customer? _selectedCustomer;
  final TextEditingController _cashCtrl = TextEditingController();
  double _cashTendered = 0.0;

  Timer? _qrTimer;
  int _qrSecondsRemaining = 180;

  @override
  void initState() {
    super.initState();
    final customers = context.read<CustomerProvider>().customers;
    if (customers.isNotEmpty) {
      _selectedCustomer = customers.first;
    }
  }

  @override
  void dispose() {
    _cashCtrl.dispose();
    _qrTimer?.cancel();
    super.dispose();
  }

  void _startQrTimer() {
    _qrTimer?.cancel();
    setState(() => _qrSecondsRemaining = 180);
    _qrTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_qrSecondsRemaining > 0) {
        setState(() => _qrSecondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTimer(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _setCash(double amount) {
    setState(() {
      _cashTendered = amount;
      _cashCtrl.text = amount > 0 ? (amount % 1 == 0 ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2)) : '';
    });
  }

  void _addCash(double increment) {
    setState(() {
      _cashTendered += increment;
      _cashCtrl.text = _cashTendered % 1 == 0 ? _cashTendered.toStringAsFixed(0) : _cashTendered.toStringAsFixed(2);
    });
  }

  void _onCashTextChanged(String val) {
    final parsed = double.tryParse(val.trim()) ?? 0.0;
    setState(() {
      _cashTendered = parsed;
    });
  }

  void _openCustomerPicker() async {
    final chosen = await Navigator.push<Customer>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerPickerScreen(selectedCustomer: _selectedCustomer),
      ),
    );
    if (chosen != null) {
      setState(() => _selectedCustomer = chosen);
    }
  }

  void _autoStartEcoPayment() async {
    final billProvider = context.read<BillProvider>();
    final auth = context.read<AuthProvider>();

    _startQrTimer();

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
        shopName: auth.shopName,
        ownerName: auth.ownerName,
        phone: auth.phone,
        address: auth.address,
        gstin: auth.gstin,
        merchantId: auth.merchantId,
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
    } else if (_selectedMode == PaymentMode.upi) {
      if (auth.upiId.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please upload or set up your Store UPI QR first in Settings.'),
            backgroundColor: AppColors.chaiGold,
            action: SnackBarAction(
              label: 'CONFIGURE',
              textColor: Colors.black,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShopProfileScreen()),
                );
              },
            ),
          ),
        );
        return;
      }
      final bill = billProvider.completeManualBill(
        PaymentMode.upi,
        customerName: _selectedCustomer?.name,
        customerPhone: _selectedCustomer?.phone,
        khataCustomerId: _selectedCustomer?.id,
        apiService: apiService,
        shopName: auth.shopName,
        ownerName: auth.ownerName,
        phone: auth.phone,
        address: auth.address,
        gstin: auth.gstin,
        merchantId: auth.merchantId,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BillSuccessScreen(bill: bill)),
      );
    } else if (_selectedMode == PaymentMode.pending) {
      final bill = billProvider.completeManualBill(
        PaymentMode.pending,
        customerName: _selectedCustomer?.name ?? 'Khata Customer',
        customerPhone: _selectedCustomer?.phone,
        khataCustomerId: _selectedCustomer?.id,
        apiService: apiService,
        shopName: auth.shopName,
        ownerName: auth.ownerName,
        phone: auth.phone,
        address: auth.address,
        gstin: auth.gstin,
        merchantId: auth.merchantId,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BillSuccessScreen(bill: bill)),
      );
    } else {
      final bill = billProvider.completeManualBill(
        _selectedMode,
        customerName: _selectedCustomer?.name,
        customerPhone: _selectedCustomer?.phone,
        khataCustomerId: _selectedCustomer?.id,
        apiService: apiService,
        shopName: auth.shopName,
        ownerName: auth.ownerName,
        phone: auth.phone,
        address: auth.address,
        gstin: auth.gstin,
        merchantId: auth.merchantId,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BillSuccessScreen(bill: bill)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final billProvider = context.watch<BillProvider>();
    final auth = context.watch<AuthProvider>();
    final total = billProvider.currentTotal;
    final changeDue = _cashTendered >= total ? _cashTendered - total : 0.0;
    final shortfall = _cashTendered > 0 && _cashTendered < total ? total - _cashTendered : 0.0;

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
              width: double.infinity,
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
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${total.toStringAsFixed(0)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.terracotta,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${billProvider.itemCount} Items',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.terracotta,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              context.tr('payment_mode'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildModeCard(
                    mode: PaymentMode.cash,
                    title: context.tr('cash'),
                    subtitle: 'Drawer / Tender',
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
                    onTap: () {
                      setState(() => _selectedMode = PaymentMode.upi);
                      _startQrTimer();
                    },
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('cash_received').toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary),
                        ),
                        if (_cashTendered > 0)
                          InkWell(
                            onTap: () => _setCash(0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.error.withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                context.tr('clear'),
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.error),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _cashCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: _onCashTextChanged,
                      style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.currency_rupee_rounded, size: 22, color: AppColors.forestMint),
                        hintText: '0',
                        suffixIcon: IconButton(
                          icon: Icon(Icons.check_circle_outline_rounded, color: AppColors.forestMint),
                          tooltip: 'Set Exact',
                          onPressed: () => _setCash(total),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _setCash(total),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.forestMint),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: Text(
                              'Exact: ₹${total.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.forestMint),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _setCash((total / 100).ceil() * 100.0),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.borderSubtle),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: Text(
                              'Round: ₹${((total / 100).ceil() * 100).toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'ADD CURRENCY NOTES',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildAddDenominationChip('+₹500', 500, AppColors.forestMint),
                        _buildAddDenominationChip('+₹200', 200, AppColors.chaiGold),
                        _buildAddDenominationChip('+₹100', 100, AppColors.terracotta),
                        _buildAddDenominationChip('+₹50', 50, AppColors.info),
                        _buildAddDenominationChip('+₹20', 20, AppColors.forestMint),
                        _buildAddDenominationChip('+₹10', 10, AppColors.chaiGold),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'ADD COINS',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildAddDenominationChip('+₹20 coin', 20, AppColors.borderSubtle, isCoin: true),
                        _buildAddDenominationChip('+₹10 coin', 10, AppColors.borderSubtle, isCoin: true),
                        _buildAddDenominationChip('+₹5 coin', 5, AppColors.borderSubtle, isCoin: true),
                        _buildAddDenominationChip('+₹2 coin', 2, AppColors.borderSubtle, isCoin: true),
                        _buildAddDenominationChip('+₹1 coin', 1, AppColors.borderSubtle, isCoin: true),
                      ],
                    ),

                    if (_cashTendered > 0) ...[
                      const SizedBox(height: 16),
                      Divider(color: AppColors.borderSubtle),
                      const SizedBox(height: 10),

                      if (_cashTendered >= total) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${context.tr('change_return')}:', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                            Text(
                              '₹${changeDue.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.forestMint),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${context.tr('shortfall_due')}:', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.chaiGold)),
                            Text(
                              '₹${shortfall.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.chaiGold),
                            ),
                          ],
                        ),
                        if (_selectedCustomer != null) ...[
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () {
                              setState(() => _selectedMode = PaymentMode.pending);
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.chaiGold.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.chaiGold),
                              ),
                              child: Center(
                                child: Text(
                                  'Record remaining ₹${shortfall.toStringAsFixed(0)} in ${_selectedCustomer!.name} Khata',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.chaiGold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (_selectedMode == PaymentMode.ecoWallet && billProvider.activeQrData != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.terracotta.withAlpha(90), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'SCAN TO PAY VIA ECO WALLET',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.terracotta),
                    ),
                    const SizedBox(height: 14),

                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(30),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: billProvider.activeQrData!,
                          version: QrVersions.auto,
                          size: 190.0,
                          backgroundColor: Colors.white,
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.black,
                          ),
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _qrSecondsRemaining > 30 ? AppColors.forestMint.withAlpha(25) : AppColors.error.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _qrSecondsRemaining > 30 ? AppColors.forestMint.withAlpha(90) : AppColors.error.withAlpha(90),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: _qrSecondsRemaining > 30 ? AppColors.forestMint : AppColors.error,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _qrSecondsRemaining > 0
                                ? 'QR Expires in ${_formatTimer(_qrSecondsRemaining)}'
                                : 'QR Code Expired',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _qrSecondsRemaining > 30 ? AppColors.forestMint : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_qrSecondsRemaining == 0) ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          _autoStartEcoPayment();
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('REGENERATE QR CODE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracotta,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.terracotta),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Listening for instant payment confirmation...',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (_selectedMode == PaymentMode.upi) ...[
              if (auth.upiId.trim().isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.chaiGold.withAlpha(100), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.chaiGold.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.qr_code_scanner_rounded, size: 30, color: AppColors.chaiGold),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'STORE UPI QR NOT CONFIGURED',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: AppColors.chaiGold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please upload or scan your store UPI QR code in Settings before using this feature.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ShopProfileScreen()),
                          );
                        },
                        icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                        label: const Text('SETUP STORE UPI QR NOW'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.chaiGold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.info.withAlpha(90), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'SCAN TO PAY VIA ANY UPI APP',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.info),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Google Pay • PhonePe • Paytm • BHIM',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 14),

                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(30),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: 'upi://pay?pa=${Uri.encodeComponent(auth.upiId.trim())}&pn=${Uri.encodeComponent(auth.shopName.isNotEmpty ? auth.shopName : "Dukaan Dost")}&am=${total.toStringAsFixed(2)}&cu=INR&tn=Store%20Bill',
                            version: QrVersions.auto,
                            size: 190.0,
                            backgroundColor: Colors.white,
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black,
                            ),
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _qrSecondsRemaining > 30 ? AppColors.info.withAlpha(25) : AppColors.error.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _qrSecondsRemaining > 30 ? AppColors.info.withAlpha(90) : AppColors.error.withAlpha(90),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: _qrSecondsRemaining > 30 ? AppColors.info : AppColors.error,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _qrSecondsRemaining > 0
                                  ? 'Dynamic UPI Expires in ${_formatTimer(_qrSecondsRemaining)}'
                                  : 'UPI QR Expired',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _qrSecondsRemaining > 30 ? AppColors.info : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],

            if (_selectedMode == PaymentMode.pending) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.chaiGold,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('khata_customer_required').toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AppColors.chaiGold,
                          ),
                        ),
                        InkWell(
                          onTap: _openCustomerPicker,
                          child: Text(
                            _selectedCustomer != null ? context.tr('change_customer') : context.tr('select_customer'),
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.terracotta),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_selectedCustomer != null) ...[
                      InkWell(
                        onTap: _openCustomerPicker,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withAlpha(50),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    _selectedCustomer!.name.isNotEmpty ? _selectedCustomer!.name[0].toUpperCase() : 'C',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.terracotta),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedCustomer!.name,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                    ),
                                    Text(
                                      _selectedCustomer!.phone,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                    if (_selectedCustomer!.address.isNotEmpty) ...[
                                      Text(
                                        _selectedCustomer!.address,
                                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (_selectedCustomer!.dueAmount > 0) ...[
                                    Text(
                                      'Due: ₹${_selectedCustomer!.dueAmount.toStringAsFixed(0)}',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.chaiGold),
                                    ),
                                  ],
                                  const SizedBox(height: 2),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: _openCustomerPicker,
                        icon: const Icon(Icons.person_search_rounded, size: 18),
                        label: Text(context.tr('search_customer')),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          side: BorderSide(color: AppColors.borderSubtle),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (_selectedMode != PaymentMode.ecoWallet) ...[
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
          ],
        ),
      ),
    );
  }

  Widget _buildAddDenominationChip(String label, double amount, Color accentColor, {bool isCoin = false}) {
    return ActionChip(
      avatar: isCoin ? Icon(Icons.monetization_on_outlined, size: 14, color: AppColors.textSecondary) : null,
      label: Text(label),
      onPressed: () => _addCash(amount),
      backgroundColor: AppColors.surface,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.borderSubtle),
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
          color: isSelected ? color.withAlpha(25) : AppColors.surface,
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
