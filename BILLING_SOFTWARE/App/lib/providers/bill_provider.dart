import 'dart:async';
import 'package:flutter/material.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import '../models/product.dart';
import '../core/api_service.dart';

class BillProvider extends ChangeNotifier {
  final List<BillItem> _currentItems = [];
  final List<Bill> _completedBills = [];

  double _todaySales = 0.0;
  int _todayBillCount = 0;
  bool _isLoadingBills = false;

  List<BillItem> get currentItems => List.unmodifiable(_currentItems);
  List<Bill> get completedBills => List.unmodifiable(_completedBills);

  double get todaySales => _todaySales > 0 ? _todaySales : _completedBills
      .where((b) => b.status == BillStatus.completed)
      .fold(0, (sum, b) => sum + b.totalAmount);

  int get todayBillCount => _todayBillCount > 0 ? _todayBillCount : _completedBills.length;
  bool get isLoadingBills => _isLoadingBills;

  double get currentTotal => _currentItems.fold(0, (sum, item) => sum + item.totalPrice);
  int get itemCount => _currentItems.fold(0, (sum, item) => sum + item.quantity);

  bool _isCreatingPayment = false;
  bool _isCheckingStatus = false;
  String? _activeQrData;
  String? _activePaymentId;
  String? _errorMessage;
  Timer? _pollingTimer;
  Timer? _countdownTimer;
  int _remainingSeconds = 300;

  bool get isCreatingPayment => _isCreatingPayment;
  bool get isCheckingStatus => _isCheckingStatus;
  String? get activeQrData => _activeQrData;
  String? get activePaymentId => _activePaymentId;
  String? get errorMessage => _errorMessage;
  int get remainingSeconds => _remainingSeconds;

  String get formattedCountdown {
    final minutes = (_remainingSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

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

  void deleteItem(Product product) {
    _currentItems.removeWhere((item) => item.product.id == product.id);
    notifyListeners();
  }

  void clearCart() {
    _currentItems.clear();
    _activeQrData = null;
    _activePaymentId = null;
    _errorMessage = null;
    _isCreatingPayment = false;
    stopPolling();
    notifyListeners();
  }

  Future<void> fetchBills(ApiService apiService) async {
    _isLoadingBills = true;
    notifyListeners();

    try {
      final response = await apiService.getBills();
      if (response["success"] == true) {
        _todaySales = (response["todaySales"] as num?)?.toDouble() ?? 0.0;
        _todayBillCount = (response["todayBillCount"] as num?)?.toInt() ?? 0;

        if (response["data"] is List) {
          final List<dynamic> billsList = response["data"];
          _completedBills.clear();
          for (final b in billsList) {
            final rawItems = b["items"] is List ? b["items"] as List : [];
            final items = rawItems.map((item) {
              final product = Product(
                id: item["product_id"] ?? "p_${DateTime.now().millisecondsSinceEpoch}",
                name: item["name"] ?? "Item",
                price: (item["price"] as num?)?.toDouble() ?? 0.0,
                category: "General",
                unit: "pcs",
                stock: 10,
                icon: "box",
              );
              return BillItem(
                product: product,
                quantity: (item["quantity"] as num?)?.toInt() ?? 1,
              );
            }).toList();

            final modeStr = b["payment_mode"]?.toString().toLowerCase() ?? "cash";
            PaymentMode mode = PaymentMode.cash;
            if (modeStr.contains("upi")) mode = PaymentMode.upi;
            if (modeStr.contains("eco") || modeStr.contains("wallet")) mode = PaymentMode.ecoWallet;
            if (modeStr.contains("pending") || modeStr.contains("khata")) mode = PaymentMode.pending;

            final statusStr = b["status"]?.toString().toLowerCase() ?? "completed";
            BillStatus status = statusStr == "pending" ? BillStatus.pending : BillStatus.completed;

            _completedBills.add(Bill(
              billId: b["bill_id"] ?? "BILL_${DateTime.now().millisecondsSinceEpoch}",
              items: items,
              totalAmount: (b["total_amount"] as num?)?.toDouble() ?? 0.0,
              timestamp: b["createdAt"] != null ? DateTime.tryParse(b["createdAt"]) ?? DateTime.now() : DateTime.now(),
              paymentMode: mode,
              status: status,
              customerName: b["customer_name"] ?? "Counter Customer",
            ));
          }
        }
      }
    } catch (_) {}

    _isLoadingBills = false;
    notifyListeners();
  }

  Future<bool> initiateEcoPayment(
    ApiService apiService, {
    String? merchantId,
    String? shopName,
    String? ownerName,
  }) async {
    if (_currentItems.isEmpty) return false;

    _isCreatingPayment = true;
    _errorMessage = null;
    _remainingSeconds = 300;
    notifyListeners();

    try {
      final orderId = "BILL-${DateTime.now().millisecondsSinceEpoch}";
      final amount = currentTotal;
      final description = "Dukaan Dost Bill (${_currentItems.length} items)";

      final response = await apiService.createPayment(
        orderId: orderId,
        amount: amount,
        description: description,
        merchantId: merchantId,
        shopName: shopName,
        ownerName: ownerName,
      );

      final data = response["data"] ?? response["payment"];

      if (response["success"] == true && data != null) {
        _activePaymentId = data["payment_id"];
        _activeQrData = data["qr_data"] ?? "ecowallet://pay?merchant=${apiService.apiKey.isNotEmpty ? apiService.apiKey : 'mch_store'}&amount=$amount&payment_id=$_activePaymentId";
        _isCreatingPayment = false;
        notifyListeners();

        _startCountdownTimer();
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

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        stopPolling();
        _activeQrData = null;
        _errorMessage = "QR Session Expired (5 min limit). Please tap to generate a new QR.";
        notifyListeners();
      }
    });
  }

  void startStatusPolling(ApiService apiService, {Function(Bill)? onSuccess}) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_activePaymentId == null) {
        stopPolling();
        return;
      }

      try {
        final response = await apiService.checkPaymentStatus(_activePaymentId!);
        final data = response["data"] ?? response["payment"];

        if (response["success"] == true && data != null) {
          final status = data["status"];

          if (status == "completed") {
            final completedPaymentId = _activePaymentId;
            stopPolling();
            _isCheckingStatus = false;
            _activePaymentId = null;
            _activeQrData = null;

            final newBill = Bill(
              billId: data["order_id"] ?? "BILL-${DateTime.now().millisecondsSinceEpoch}",
              items: List.from(_currentItems),
              totalAmount: currentTotal,
              timestamp: DateTime.now(),
              paymentMode: PaymentMode.ecoWallet,
              status: BillStatus.completed,
              ecoPaymentId: completedPaymentId,
              ecoTransactionId: data["transaction_id"],
              customerName: data["payer_name"] ?? "ECO Customer",
            );

            _completedBills.insert(0, newBill);
            _todaySales += newBill.totalAmount;
            _todayBillCount++;

            apiService.saveBill(
              billId: newBill.billId,
              items: newBill.items,
              totalAmount: newBill.totalAmount,
              paymentMode: "ecoWallet",
              customerName: newBill.customerName,
            );

            clearCart();
            if (onSuccess != null) onSuccess(newBill);
          } else if (status == "expired" || status == "failed") {
            stopPolling();
            _isCheckingStatus = false;
            _activePaymentId = null;
            _activeQrData = null;
            _errorMessage = "QR Payment expired after 5 minutes.";
            notifyListeners();
          }
        }
      } catch (_) {}
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _isCheckingStatus = false;
  }

  Bill completeManualBill(PaymentMode mode, {String? customerName, ApiService? apiService}) {
    final newBill = Bill(
      billId: "BILL-${DateTime.now().millisecondsSinceEpoch}",
      items: List.from(_currentItems),
      totalAmount: currentTotal,
      timestamp: DateTime.now(),
      paymentMode: mode,
      status: mode == PaymentMode.pending ? BillStatus.pending : BillStatus.completed,
      customerName: customerName ?? "Counter Customer",
    );

    _completedBills.insert(0, newBill);
    if (newBill.status == BillStatus.completed) {
      _todaySales += newBill.totalAmount;
      _todayBillCount++;
    }

    if (apiService != null) {
      apiService.saveBill(
        billId: newBill.billId,
        items: newBill.items,
        totalAmount: newBill.totalAmount,
        paymentMode: mode.name,
        customerName: newBill.customerName,
      );
    }

    clearCart();
    return newBill;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
