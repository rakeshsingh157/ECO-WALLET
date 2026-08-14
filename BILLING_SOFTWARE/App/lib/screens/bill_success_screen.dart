import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/bill.dart';
import '../providers/auth_provider.dart';
import 'main_shell.dart';

class BillSuccessScreen extends StatelessWidget {
  final Bill bill;

  const BillSuccessScreen({super.key, required this.bill});

  String _getInvoiceUrl(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final base = auth.baseUrl.isNotEmpty ? auth.baseUrl : "http://10.0.2.2:5001/api";
    final cleanBase = base.endsWith('/api') ? base : '$base/api';
    return "$cleanBase/merchant/invoice/${bill.billId}";
  }

  @override
  Widget build(BuildContext context) {
    final invoiceUrl = _getInvoiceUrl(context);

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
                    child: Icon(Icons.check_circle_rounded, color: AppColors.warmCoral, size: 54),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Payment Completed',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textOnWarm,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bill #${bill.billId}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textOnWarm.withValues(alpha: 0.8),
                  ),
                ),

                const SizedBox(height: 24),

                GlassCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 22,
                  color: AppColors.darkCard.withValues(alpha: 0.95),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Amount Paid',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(bill.totalAmount),
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.warmCoral,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.darkBorder),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Payment Mode', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
                          Text(
                            bill.paymentMode.name.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Items Count', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
                          Text(
                            '${bill.items.length} items',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (bill.customerName != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Customer', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
                            Text(
                              bill.customerName!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                GlassCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 22,
                  color: AppColors.darkCard.withValues(alpha: 0.95),
                  child: Column(
                    children: [
                      Text(
                        'Tax Invoice Available',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warmPeach,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scan QR with camera or click share link',
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
                          side: const BorderSide(color: Colors.white38),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const MainShell()),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(
                          'New Bill',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
