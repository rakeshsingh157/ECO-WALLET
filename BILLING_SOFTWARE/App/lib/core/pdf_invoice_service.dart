import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/bill.dart';

class PdfInvoiceService {
  static Future<Uint8List> generateInvoiceBytes(
    Bill bill, {
    String? shopName,
    String? ownerName,
    String? phone,
    String? address,
    String? gstin,
    String? baseUrl,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.plusJakartaSansRegular();
    final fontBold = await PdfGoogleFonts.plusJakartaSansBold();
    final fontExtraBold = await PdfGoogleFonts.plusJakartaSansExtraBold();

    final dateFormatted = DateFormat('dd MMM yyyy, hh:mm a').format(bill.timestamp);
    final displayShopName = (shopName != null && shopName.trim().isNotEmpty) ? shopName.trim() : 'Dukaan Dost Retail Store';
    final displayPhone = (phone != null && phone.trim().isNotEmpty) ? phone.trim() : '+91 98765 43210';
    final displayAddress = (address != null && address.trim().isNotEmpty) ? address.trim() : 'Market Area, Main Road, India';
    final displayOwner = (ownerName != null && ownerName.trim().isNotEmpty) ? ownerName.trim() : 'Store Merchant';

    final cleanBase = (baseUrl != null && baseUrl.trim().isNotEmpty)
        ? baseUrl.trim().replaceAll(RegExp(r'/api/?$'), '')
        : 'https://eco-wallet-1.onrender.com';
    final invoiceQrPayload = '$cleanBase/invoice/${bill.billId}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        displayShopName.toUpperCase(),
                        style: pw.TextStyle(
                          font: fontExtraBold,
                          fontSize: 20,
                          color: const PdfColor.fromInt(0xFFE8592A),
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Prop: $displayOwner | Ph: $displayPhone',
                        style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        displayAddress,
                        style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700),
                      ),
                      if (gstin != null && gstin.trim().isNotEmpty)
                        pw.Text(
                          'GSTIN: ${gstin.trim()}',
                          style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey800),
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: const PdfColor.fromInt(0xFFE8592A),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'TAX INVOICE',
                          style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.white),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Invoice #: ${bill.billId}',
                        style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.black),
                      ),
                      pw.Text(
                        'Date: $dateFormatted',
                        style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1, color: const PdfColor.fromInt(0xFFE2E8F0)),
              pw.SizedBox(height: 10),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BILLED TO / CUSTOMER',
                        style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey600),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        bill.customerName ?? 'Counter Customer',
                        style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.black),
                      ),
                      if (bill.customerPhone != null && bill.customerPhone!.isNotEmpty)
                        pw.Text(
                          'Phone: ${bill.customerPhone}',
                          style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700),
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'PAYMENT METHOD',
                        style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey600),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        bill.paymentMode.name.toUpperCase(),
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 11,
                          color: const PdfColor.fromInt(0xFF1E824C),
                        ),
                      ),
                      if (bill.ecoTransactionId != null)
                        pw.Text(
                          'Txn: ${bill.ecoTransactionId}',
                          style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey700),
                        ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              pw.Table(
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0), width: 0.8),
                  bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 1.2),
                ),
                columnWidths: {
                  0: const pw.FixedColumnWidth(28),
                  1: const pw.FlexColumnWidth(4),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                  4: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1F5F9)),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('#', style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey800)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('ITEM DESCRIPTION', style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey800)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('QTY / WEIGHT', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey800)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('RATE (INR)', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey800)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('AMOUNT (INR)', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey800)),
                      ),
                    ],
                  ),
                  ...bill.items.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final item = entry.value;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: pw.Text('$idx', style: pw.TextStyle(font: font, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: pw.Text(item.product.name, style: pw.TextStyle(font: fontBold, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: pw.Text(item.formattedQuantity, textAlign: pw.TextAlign.center, style: pw.TextStyle(font: font, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: pw.Text('${item.product.price.toStringAsFixed(2)} / ${item.product.unit}', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: font, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: pw.Text(item.totalPrice.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 9)),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 16),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 74,
                        height: 74,
                        child: pw.BarcodeWidget(
                          data: invoiceQrPayload,
                          barcode: pw.Barcode.qrCode(),
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Scan QR to verify invoice',
                            style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.black),
                          ),
                          pw.Text(
                            'Auth ID: ${bill.billId.hashCode.abs()}',
                            style: pw.TextStyle(font: font, fontSize: 7, color: PdfColors.grey600),
                          ),
                          if (bill.isReturned)
                            pw.Container(
                              margin: const pw.EdgeInsets.only(top: 4),
                              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: pw.BoxDecoration(
                                color: const PdfColor.fromInt(0xFFDC2626),
                                borderRadius: pw.BorderRadius.circular(3),
                              ),
                              child: pw.Text(
                                'RETURNED & REFUNDED',
                                style: pw.TextStyle(font: fontBold, fontSize: 7, color: PdfColors.white),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  pw.Container(
                    width: 200,
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Subtotal:', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
                            pw.Text('INR ${bill.totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('GST / Taxes:', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700)),
                            pw.Text('INR 0.00 (Incl.)', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey700)),
                          ],
                        ),
                        if (bill.refundedAmount > 0) ...[
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Refunded / Returned:', style: pw.TextStyle(font: fontBold, fontSize: 9, color: const PdfColor.fromInt(0xFFDC2626))),
                              pw.Text('- INR ${bill.refundedAmount.toStringAsFixed(2)}', style: pw.TextStyle(font: fontBold, fontSize: 9, color: const PdfColor.fromInt(0xFFDC2626))),
                            ],
                          ),
                        ],
                        pw.SizedBox(height: 6),
                        pw.Divider(thickness: 1, color: const PdfColor.fromInt(0xFFE2E8F0)),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('GRAND TOTAL:', style: pw.TextStyle(font: fontExtraBold, fontSize: 12, color: const PdfColor.fromInt(0xFFE8592A))),
                            pw.Text('INR ${bill.netAmount.toStringAsFixed(2)}', style: pw.TextStyle(font: fontExtraBold, fontSize: 14, color: const PdfColor.fromInt(0xFFE8592A))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              pw.Divider(thickness: 0.5, color: const PdfColor.fromInt(0xFFE2E8F0)),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Thank you for your business! Powered by Dukaan Dost Smart Billing.',
                    style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'E. & O.E.',
                    style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printOrShareInvoice(
    BuildContext context,
    Bill bill, {
    String? shopName,
    String? ownerName,
    String? phone,
    String? address,
    String? gstin,
    String? baseUrl,
  }) async {
    final bytes = await generateInvoiceBytes(
      bill,
      shopName: shopName,
      ownerName: ownerName,
      phone: phone,
      address: address,
      gstin: gstin,
      baseUrl: baseUrl,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Invoice_${bill.billId}',
    );
  }

  static Future<void> sharePdfInvoice(
    BuildContext context,
    Bill bill, {
    String? shopName,
    String? ownerName,
    String? phone,
    String? address,
    String? gstin,
    String? baseUrl,
  }) async {
    final bytes = await generateInvoiceBytes(
      bill,
      shopName: shopName,
      ownerName: ownerName,
      phone: phone,
      address: address,
      gstin: gstin,
      baseUrl: baseUrl,
    );

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Invoice_${bill.billId}.pdf',
    );
  }
}
