import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class EcoPaymentScreen extends StatefulWidget {
  const EcoPaymentScreen({super.key});

  @override
  State<EcoPaymentScreen> createState() => _EcoPaymentScreenState();
}

class _EcoPaymentScreenState extends State<EcoPaymentScreen> {
  final _amountController = TextEditingController(text: '100');

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final merchantId = auth.merchantId.isNotEmpty ? auth.merchantId : 'MRC-SHOP01';
    final amount = double.tryParse(_amountController.text) ?? 100.0;
    final qrData = "eco://pay/PAY-QUICK?amount=$amount&merchant=$merchantId";

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/coin.png',
              width: 30,
              height: 30,
              errorBuilder: (c, e, s) => const Icon(Icons.stars_rounded, color: AppColors.warmPeach),
            ),
            const SizedBox(width: 10),
            Text(
              'ECO Wallet Payments',
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
            // Merchant Info Banner
            GlassCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 22,
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.warmPeach.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/coin.png',
                        width: 36,
                        height: 36,
                        errorBuilder: (c, e, s) => const Icon(Icons.stars_rounded, color: AppColors.warmPeach),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.shopName,
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Merchant ID: $merchantId',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'API Active',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Dynamic Counter QR Standee Card
            GlassCard(
              padding: const EdgeInsets.all(24),
              borderRadius: 24,
              color: AppColors.darkCard.withValues(alpha: 0.95),
              child: Column(
                children: [
                  Text(
                    'Counter Payment Standee QR',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.warmPeach),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Set amount & show QR to customer',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),

                  // Amount Input
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.warmPeach),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.warmPeach),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stars_rounded, color: AppColors.warmPeach, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Receives instant payment in ECO Coins',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
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
