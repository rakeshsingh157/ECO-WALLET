import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/bill.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../core/pdf_invoice_service.dart';
import '../../providers/auth_provider.dart';
import 'return_order_screen.dart';

class SaleDetailsScreen extends StatelessWidget {
  final Bill bill;

  const SaleDetailsScreen({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'INVOICE #${bill.id}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share PDF Invoice',
            onPressed: () {
              PdfInvoiceService.sharePdfInvoice(
                context,
                bill,
                shopName: auth.shopName,
                ownerName: auth.ownerName,
                phone: auth.phone,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.shopName.isNotEmpty ? auth.shopName : 'Dukaan Dost Store',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd MMM yyyy, hh:mm a').format(bill.timestamp),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: bill.isReturned ? AppColors.error.withAlpha(40) : AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          bill.isReturned
                              ? 'RETURNED'
                              : (bill.isPartiallyReturned ? 'PARTIALLY REFUNDED' : bill.paymentMode.name.toUpperCase()),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: bill.isReturned ? AppColors.error : AppColors.forestMint,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: AppColors.borderSubtle),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(context.tr('customer'), style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary)),
                      Text(bill.customerName ?? 'Counter Customer', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(context.tr('payment_mode'), style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary)),
                      Text(bill.paymentMode.name.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.terracotta)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'ITEMIZED BREAKDOWN',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),

                  ...bill.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.product.name} (x${item.formattedQuantity})',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textPrimary),
                            ),
                          ),
                          Text(
                            '₹${item.totalPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Divider(color: AppColors.borderSubtle),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(context.tr('grand_total'), style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      Text(
                        NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(bill.totalAmount),
                        style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.terracotta),
                      ),
                    ],
                  ),

                  if (bill.refundedAmount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Refunded', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.error)),
                        Text(
                          '-₹${bill.refundedAmount.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.error),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Net Settled Total', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.forestMint)),
                        Text(
                          '₹${bill.netAmount.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.forestMint),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  Center(
                    child: Column(
                      children: [
                        QrImageView(
                          data: '${auth.baseUrl.replaceAll(RegExp(r'/api/?$'), '')}/invoice/${bill.id}',
                          version: QrVersions.auto,
                          size: 110.0,
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.textPrimary,
                          ),
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Scan to view & download PDF invoice on browser',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.terracotta),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      PdfInvoiceService.printOrShareInvoice(
                        context,
                        bill,
                        shopName: auth.shopName,
                        ownerName: auth.ownerName,
                        phone: auth.phone,
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text('Download / Print PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracotta,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (!bill.isReturned)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReturnOrderScreen(initialBill: bill),
                      ),
                    );
                  },
                  icon: Icon(Icons.assignment_return_rounded, size: 18, color: AppColors.error),
                  label: const Text('Return / Refund This Order'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withAlpha(128)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
