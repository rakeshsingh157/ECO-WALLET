import 'dart:async';
import 'package:flutter/material.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import '../models/product.dart';
import '../core/api_service.dart';

class BillProvider extends ChangeNotifier {
  final List<BillItem> _currentItems = [];
  final List<Bill> _completedBills = [
    Bill(
      billId: '1042',
      items: [],
      totalAmount: 1250.0,
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      paymentMode: PaymentMode.cash,
      status: BillStatus.completed,
      customerName: 'Rice 25kg Bag, Dal...',
    ),
    Bill(
      billId: '1041',
      items: [],
      totalAmount: 450.0,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      paymentMode: PaymentMode.pending,
      status: BillStatus.pending,
      customerName: 'Ramesh (Khata)',
    ),
    Bill(
      billId: '1040',
      items: [],
      totalAmount: 320.0,
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      paymentMode: PaymentMode.upi,
      status: BillStatus.completed,
      customerName: 'Biscuits, Soap, Oil',
    ),
  ];

  List<BillItem> get currentItems => List.unmodifiable(_currentItems);
  List<Bill> get completedBills => List.unmodifiable(_completedBills);

  double get currentTotal => _currentItems.fold(0, (sum, item) => sum + item.totalPrice);
  int get itemCount => _currentItems.fold(0, (sum, item) => sum + item.quantity);

  // Current active payment state
  bool _isCreatingPayment = false;
  bool _isCheckingStatus = false;
  String? _activeQrData;
  String? _activePaymentId;
  String? _errorMessage;
  Timer? _pollingTimer;

  bool get isCreatingPayment => _isCreatingPayment;
  bool get isCheckingStatus => _isCheckingStatus;
  String? get activeQrData => _activeQrData;
  String? get activePaymentId => _activePaymentId;
  String? get errorMessage => _errorMessage;

  // Stats
  double get todaySales => _completedBills
      .where((b) => b.status == BillStatus.completed)
      .fold(0.0, (sum, b) => sum + b.totalAmount);

  int get todayBillCount => _completedBills.where((b) => b.status == BillStatus.completed).length;

  void addItem(Product product) {
    final index = _currentItems.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _currentItems[index].quantity++;
    } else {
      _currentItems.add(BillItem(product: product, quantity: 1));
    }
    notifyListeners();
  }

  void removeItem(Product product) {
    final index = _currentItems.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      if (_currentItems[index].quantity > 1) {
        _currentItems[index].quantity--;
      } else {
        _currentItems.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _currentItems.clear();
    _activeQrData = null;
    _activePaymentId = null;
    _errorMessage = null;
    stopPolling();
    notifyListeners();
  }

  /// Create ECO Wallet merchant payment and start polling status
  Future<bool> initiateEcoPayment(ApiService apiService) async {
    if (_currentItems.isEmpty) return false;

    _isCreatingPayment = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final orderId = "BILL-${DateTime.now().millisecondsSinceEpoch}";
      final amount = currentTotal;
      final description = "Dukaan Dost Bill (${_currentItems.length} items)";

      final response = await apiService.createPayment(
        orderId: orderId,
        amount: amount,
        description: description,
      );

      final data = response["data"] ?? response["payment"];

      if (response["success"] == true && data != null) {
        _activePaymentId = data["payment_id"];
        _activeQrData = data["qr_data"] ?? "ecowallet://pay?merchant=mch_sharma_kirana&amount=$amount&payment_id=$_activePaymentId";
        _isCreatingPayment = false;
        notifyListeners();

        // Start polling for payment completion
        startStatusPolling(apiService);
        return true;
      } else {
        _errorMessage = response["message"] ?? "Failed to create payment";
        _isCreatingPayment = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _isCreatingPayment = false;
      notifyListeners();
      return false;
    }
  }

  /// Poll status every 3 seconds
  void startStatusPolling(ApiService apiService, {Function(Bill)? onSuccess}) {
    stopPolling();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_activePaymentId == null) return;
      _isCheckingStatus = true;
      notifyListeners();

      try {
        final response = await apiService.checkPaymentStatus(_activePaymentId!);
        final data = response["data"] ?? response["payment"];

        if (response["success"] == true && data != null) {
          final status = data["status"];

          if (status == "completed") {
            stopPolling();
            _isCheckingStatus = false;

            // Finalize bill
            final newBill = Bill(
              billId: data["order_id"] ?? "BILL-${DateTime.now().millisecondsSinceEpoch}",
              items: List.from(_currentItems),
              totalAmount: currentTotal,
              timestamp: DateTime.now(),
              paymentMode: PaymentMode.ecoWallet,
              status: BillStatus.completed,
              ecoPaymentId: _activePaymentId,
              ecoTransactionId: data["transaction_id"],
              customerName: data["payer_name"] ?? "ECO Customer",
            );

            _completedBills.insert(0, newBill);
            clearCart();
            if (onSuccess != null) onSuccess(newBill);
          } else if (status == "expired" || status == "failed") {
            stopPolling();
            _isCheckingStatus = false;
            _errorMessage = "Payment $status";
            notifyListeners();
          }
        }
      } catch (e) {
        // Silent error during polling retry
      }
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Complete cash/UPI bill directly
  Bill completeManualBill(PaymentMode mode, {String? customerName}) {
    final newBill = Bill(
      billId: "BILL-${DateTime.now().millisecondsSinceEpoch}",
      items: List.from(_currentItems),
      totalAmount: currentTotal,
      timestamp: DateTime.now(),
      paymentMode: mode,
      status: BillStatus.completed,
      customerName: customerName ?? "Counter Customer",
    );

    _completedBills.insert(0, newBill);
    clearCart();
    return newBill;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
