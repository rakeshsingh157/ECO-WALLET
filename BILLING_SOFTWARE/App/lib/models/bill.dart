import 'bill_item.dart';

enum PaymentMode { cash, ecoWallet, upi, pending }
enum BillStatus { pending, completed, cancelled, returned, partiallyReturned }

class ReturnRecord {
  final String returnId;
  final double amount;
  final String reason;
  final DateTime timestamp;
  final String refundMode;

  ReturnRecord({
    required this.returnId,
    required this.amount,
    required this.reason,
    required this.timestamp,
    this.refundMode = 'cash',
  });
}

class Bill {
  final String billId;
  final List<BillItem> items;
  final double totalAmount;
  double refundedAmount;
  final DateTime timestamp;
  PaymentMode paymentMode;
  BillStatus status;
  String? ecoPaymentId;
  String? ecoTransactionId;
  String? customerName;
  String? customerPhone;
  List<ReturnRecord> returnHistory;

  String get id => billId;
  double get netAmount => (totalAmount - refundedAmount) < 0 ? 0 : (totalAmount - refundedAmount);
  bool get isReturned => status == BillStatus.returned || (refundedAmount >= totalAmount && totalAmount > 0);
  bool get isPartiallyReturned => status == BillStatus.partiallyReturned || (refundedAmount > 0 && refundedAmount < totalAmount);

  Bill({
    required this.billId,
    required this.items,
    required this.totalAmount,
    this.refundedAmount = 0.0,
    required this.timestamp,
    this.paymentMode = PaymentMode.cash,
    this.status = BillStatus.pending,
    this.ecoPaymentId,
    this.ecoTransactionId,
    this.customerName,
    this.customerPhone,
    this.returnHistory = const [],
  });
}
