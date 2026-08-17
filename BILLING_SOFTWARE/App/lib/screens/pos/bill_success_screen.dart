import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../core/pdf_invoice_service.dart';
import '../../models/bill.dart';
import '../../providers/auth_provider.dart';
import '../main_shell.dart';
import 'pos_screen.dart';

class BillSuccessScreen extends StatelessWidget {
  final Bill bill;

  const BillSuccessScreen({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

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
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.forestMint.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.forestMint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  context.tr('payment_successful'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${bill.totalAmount.toStringAsFixed(2)} ${context.tr('received_via')} ${bill.paymentMode.name.toUpperCase()}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderSubtle),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
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
                          Text(
                            context.tr('bill_receipt').toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AppColors.terracotta,
                            ),
                          ),
                          Text(
                            '#${bill.id}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(context.tr('date_time'), style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary)),
                          Text(
                            DateFormat('dd MMM yyyy, hh:mm a').format(bill.timestamp.toLocal()),
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(context.tr('customer'), style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary)),
                          Text(
                            bill.customerName ?? context.tr('counter_customer'),
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(context.tr('payment_mode'), style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary)),
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

                      const SizedBox(height: 14),
                      Divider(color: AppColors.borderSubtle),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr('grand_total'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '₹${bill.totalAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.terracotta,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

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
                            const SizedBox(height: 4),
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

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          PdfInvoiceService.sharePdfInvoice(
                            context,
                            bill,
                            shopName: auth.shopName,
                            ownerName: auth.ownerName,
                            phone: auth.phone,
                          );
                        },
                        icon: Icon(Icons.share_rounded, color: AppColors.terracotta, size: 18),
                        label: Text(
                          context.tr('share_pdf'),
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
                          PdfInvoiceService.printOrShareInvoice(
                            context,
                            bill,
                            shopName: auth.shopName,
                            ownerName: auth.ownerName,
                            phone: auth.phone,
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                        label: Text(context.tr('download_pdf')),
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
                          side: BorderSide(color: AppColors.borderSubtle),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          context.tr('home'),
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const MainShell()),
                            (route) => false,
                          );
                          Navigator.of(context).push(
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
                          context.tr('next_bill'),
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
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
}
