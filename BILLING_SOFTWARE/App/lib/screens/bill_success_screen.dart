import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../core/theme.dart';
import '../models/bill.dart';
import 'main_shell.dart';

class BillSuccessScreen extends StatelessWidget {
  final Bill bill;

  const BillSuccessScreen({super.key, required this.bill});

  String _getInvoiceUrl() {
    return "http://10.0.2.2:8000/api/merchant/invoice/${bill.billId}";
  }

  @override
  Widget build(BuildContext context) {
    final invoiceUrl = _getInvoiceUrl();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.warmGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Cute Quicksand Receipt Character Badge
                Container(
                  width: 96,
                  height: 96,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.darkNavy,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 60,
                      color: AppColors.success,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Payment Successful',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textOnWarm,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bill #${bill.billId} completed',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textOnWarm.withValues(alpha: 0.85),
                  ),
                ),

                const SizedBox(height: 24),

                // Bill Details Card
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 22,
                  color: AppColors.darkCard.withValues(alpha: 0.95),
                  child: Column(
                    children: [
                      _buildDetailRow('Total Amount Paid', '₹${bill.totalAmount.toStringAsFixed(0)}', isHighlight: true),
                      const Divider(color: AppColors.glassBorder, height: 20),
                      _buildDetailRow('Payment Mode', _getPaymentModeLabel(bill.paymentMode)),
                      const SizedBox(height: 10),
                      _buildDetailRow('Date & Time', DateFormat('dd MMM yyyy, hh:mm a').format(bill.timestamp)),
                      if (bill.customerName != null) ...[
                        const SizedBox(height: 10),
                        _buildDetailRow('Customer', bill.customerName!),
                      ],
                      if (bill.ecoTransactionId != null) ...[
                        const SizedBox(height: 10),
                        _buildDetailRow('ECO Txn ID', bill.ecoTransactionId!),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Download Invoice QR Section (Scan to Auto-Download Invoice)
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 22,
                  color: AppColors.darkCard.withValues(alpha: 0.95),
                  child: Column(
                    children: [
                      Text(
                        'Scan QR to Download Invoice',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warmPeach,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scan with phone camera for auto-download',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: QrImageView(
                          data: invoiceUrl,
                          version: QrVersions.auto,
                          size: 150.0,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextButton.icon(
                        onPressed: () {
                          Share.share(
                            'Here is your invoice for Bill #${bill.billId}: $invoiceUrl',
                            subject: 'Invoice #${bill.billId}',
                          );
                        },
                        icon: const Icon(Icons.share_rounded, color: AppColors.warmCoral, size: 18),
                        label: Text(
                          'Share Invoice Link',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warmCoral,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Printing receipt...')),
                          );
                        },
                        icon: const Icon(Icons.print_rounded, color: AppColors.textOnWarm, size: 18),
                        label: Text(
                          'Print Receipt',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textOnWarm,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.textOnWarm, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const MainShell()),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.add_rounded, color: AppColors.darkNavy, size: 18),
                        label: Text(
                          'New Bill',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkNavy,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isHighlight ? 18 : 13,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            color: isHighlight ? AppColors.warmPeach : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _getPaymentModeLabel(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.ecoWallet:
        return 'ECO Wallet';
      case PaymentMode.upi:
        return 'UPI';
      case PaymentMode.cash:
      default:
        return 'Cash';
    }
  }
}
