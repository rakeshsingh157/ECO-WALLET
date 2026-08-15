import 'bill_item.dart';

enum PaymentMode { cash, ecoWallet, upi, pending }
enum BillStatus { pending, completed, cancelled }

class Bill {
  final String billId;
  final List<BillItem> items;
  final double totalAmount;
  final DateTime timestamp;
  PaymentMode paymentMode;
  BillStatus status;
  String? ecoPaymentId;
  String? ecoTransactionId;
  String? customerName;

  String get id => billId;

  Bill({
    required this.billId,
    required this.items,
    required this.totalAmount,
    required this.timestamp,
    this.paymentMode = PaymentMode.cash,
    this.status = BillStatus.pending,
    this.ecoPaymentId,
    this.ecoTransactionId,
    this.customerName,
  });
}
