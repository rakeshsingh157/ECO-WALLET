import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../models/bill.dart';
import '../main_shell.dart';
import 'pos_screen.dart';

class BillSuccessScreen extends StatelessWidget {
  final Bill bill;

  const BillSuccessScreen({super.key, required this.bill});

  void _shareReceipt(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln('==============================');
    buffer.writeln('      DUKAAN DOST INVOICE     ');
    buffer.writeln('==============================');
    buffer.writeln('Invoice ID: #${bill.id}');
    buffer.writeln('Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(bill.timestamp)}');
    buffer.writeln('Customer: ${bill.customerName ?? 'Counter Customer'}');
    buffer.writeln('Payment: ${bill.paymentMode.name.toUpperCase()}');
    buffer.writeln('------------------------------');
    for (final item in bill.items) {
      buffer.writeln('${item.product.name} x${item.quantity} = ₹${item.totalPrice.toStringAsFixed(0)}');
    }
    buffer.writeln('------------------------------');
    buffer.writeln('GRAND TOTAL: ₹${bill.totalAmount.toStringAsFixed(0)}');
    buffer.writeln('==============================');
    buffer.writeln('Thank you for shopping with us!');

    Share.share(buffer.toString(), subject: 'Invoice #${bill.id}');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainShell()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Image.asset(MascotAssets.receipt, width: 80, height: 80),
                const SizedBox(height: 12),

                Text(
                  context.tr('bill_success').toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.forestMint,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bill generated and inventory updated',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
                ),

                const SizedBox(height: 20),

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
                      Text(
                        'TAX INVOICE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: AppColors.terracotta,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#${bill.id.substring(0, bill.id.length > 8 ? 8 : bill.id.length).toUpperCase()}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy • hh:mm a').format(bill.timestamp),
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                      ),

                      const SizedBox(height: 14),
                      Divider(color: AppColors.borderSubtle),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Customer', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary)),
                          Text(
                            bill.customerName ?? 'Counter Customer',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Payment Mode', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              bill.paymentMode.name.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.forestMint),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),
                      Divider(color: AppColors.borderSubtle),
                      const SizedBox(height: 10),

                      ...bill.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.product.name} (x${item.quantity})',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textPrimary),
                                ),
                              ),
                              Text(
                                '₹${item.totalPrice.toStringAsFixed(0)}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),
                      Divider(color: AppColors.borderSubtle),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr('grand_total').toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                          Text(
                            NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(bill.totalAmount),
                            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.terracotta),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Center(
                        child: QrImageView(
                          data: 'INVOICE:${bill.id}|AMT:${bill.totalAmount}',
                          version: QrVersions.auto,
                          size: 90.0,
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.textPrimary,
                          ),
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _shareReceipt(context),
                        icon: Icon(Icons.share_rounded, color: AppColors.terracotta, size: 18),
                        label: Text(
                          context.tr('share_whatsapp'),
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.terracotta),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          side: BorderSide(color: AppColors.terracotta),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Receipt sent to default thermal printer'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        icon: const Icon(Icons.print_rounded, size: 18),
                        label: Text(context.tr('print_receipt')),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: AppColors.forestMint,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const MainShell()),
                            (route) => false,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          side: BorderSide(color: AppColors.borderStrong),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          context.tr('home'),
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const PosScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: AppColors.terracotta,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          context.tr('new_bill'),
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
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
