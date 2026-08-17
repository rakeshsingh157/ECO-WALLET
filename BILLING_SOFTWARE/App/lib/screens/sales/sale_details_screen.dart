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
          '${context.tr('invoice').toUpperCase()} #${bill.id}',
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
            tooltip: context.tr('share_pdf'),
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
                            auth.shopName.isNotEmpty ? auth.shopName : context.tr('app_title'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd MMM yyyy, hh:mm a').format(bill.timestamp.toLocal()),
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
                              ? context.tr('returned').toUpperCase()
                              : (bill.isPartiallyReturned ? context.tr('partial_return').toUpperCase() : bill.paymentMode.name.toUpperCase()),
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
                      Text(bill.customerName ?? context.tr('counter_customer'), style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
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
                    context.tr('itemized_breakdown').toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),

                  ...bill.items.map(
                    (item) {
                      final isFullyRet = item.isFullyReturned;
                      final isPartRet = item.isPartiallyReturned;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '${item.product.name} (x${item.formattedQuantity})',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            color: isFullyRet ? AppColors.textMuted : AppColors.textPrimary,
                                            decoration: isFullyRet ? TextDecoration.lineThrough : null,
                                          ),
                                        ),
                                      ),
                                      if (isFullyRet) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(color: AppColors.error.withAlpha(25), borderRadius: BorderRadius.circular(4)),
                                          child: Text(context.tr('returned').toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.error)),
                                        ),
                                      ] else if (isPartRet) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(color: AppColors.warning.withAlpha(25), borderRadius: BorderRadius.circular(4)),
                                          child: Text(context.tr('partial').toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.warning)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (isPartRet)
                                    Text(
                                      '${item.formatQuantityValue(item.returnedQuantity)} ${context.tr('returned')}',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.w600),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${item.totalPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isFullyRet ? AppColors.textMuted : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
                        Text(context.tr('total_refunded'), style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.error)),
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
                        Text(context.tr('net_settled_total'), style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.forestMint)),
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
                          data: '${auth.baseUrl.replaceAll(RegExp(r'/api/?$'), '')}/invoice/${bill.id}${Uri(queryParameters: {
                            if (auth.shopName.isNotEmpty) 'shop_name': auth.shopName,
                            if (auth.ownerName.isNotEmpty) 'owner_name': auth.ownerName,
                            if (auth.phone.isNotEmpty) 'phone': auth.phone,
                            if (auth.address.isNotEmpty) 'address': auth.address,
                            if (auth.gstin.isNotEmpty) 'gstin': auth.gstin,
                          }).query.isNotEmpty ? '?${Uri(queryParameters: {
                            if (auth.shopName.isNotEmpty) 'shop_name': auth.shopName,
                            if (auth.ownerName.isNotEmpty) 'owner_name': auth.ownerName,
                            if (auth.phone.isNotEmpty) 'phone': auth.phone,
                            if (auth.address.isNotEmpty) 'address': auth.address,
                            if (auth.gstin.isNotEmpty) 'gstin': auth.gstin,
                          }).query}' : ''}',
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
                          context.tr('scan_qr_invoice_hint'),
                          textAlign: TextAlign.center,
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
                    label: Text(context.tr('download_print_pdf')),
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
                  label: Text(context.tr('return_refund_order')),
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
