/// ECO Wallet — Wallet State Provider
import 'dart:async';
import 'package:flutter/material.dart';
import '../core/api_service.dart';

class WalletProvider extends ChangeNotifier {
  bool _isLoading = false;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _leaderboard = [];
  double _weeklyEarnings = 0;
  Map<String, dynamic>? _bankStatus;
  String? _qrImage;
  int _totalTransactions = 0;
  Timer? _pollingTimer;

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get transactions => _transactions;
  List<Map<String, dynamic>> get tasks => _tasks;
  List<Map<String, dynamic>> get leaderboard => _leaderboard;
  double get weeklyEarnings => _weeklyEarnings;
  Map<String, dynamic>? get bankStatus => _bankStatus;
  String? get qrImage => _qrImage;
  int get totalTransactions => _totalTransactions;

  /// Fetch transaction history
  Future<void> fetchTransactions({String filter = 'all', int page = 1, bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final res = await ApiService.get('/transactions?filter=$filter&page=$page&limit=20');
      if (res['success'] == true) {
        final data = res['data'];
        if (page == 1) {
          _transactions = List<Map<String, dynamic>>.from(data['transactions']);
        } else {
          _transactions.addAll(List<Map<String, dynamic>>.from(data['transactions']));
        }
        _totalTransactions = data['pagination']['total'] ?? 0;
      }
    } catch (e) {
      print('Fetch transactions error: $e');
    }

    if (!silent) {
      _isLoading = false;
      notifyListeners();
    } else {
      notifyListeners(); // still notify for new data
    }
  }

  /// Start Realtime Polling
  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      fetchTransactions(silent: true);
      fetchLeaderboard();
    });
  }

  /// Stop Realtime Polling
  void stopPolling() {
    _pollingTimer?.cancel();
  }

  /// Send money by user_id
  Future<Map<String, dynamic>> sendMoney(
    String receiverId,
    double amount, {
    String? pin,
    String? description,
    String? idempotencyKey,
    String? paymentId,
  }) async {
    try {
      final body = {
        'receiver_id': receiverId,
        'amount': amount,
        if (pin != null) 'pin': pin,
        if (description != null) 'description': description,
        if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
        if (paymentId != null) 'payment_id': paymentId,
      };
      final res = await ApiService.post('/transfer/send', body);
      return res;
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  /// Send money via QR payload
  Future<Map<String, dynamic>> sendMoneyQR(String qrPayload, double amount, {String? pin, String? idempotencyKey}) async {
    try {
      final res = await ApiService.post('/transfer/qr-send', {
        'qr_payload': qrPayload,
        'amount': amount,
        if (pin != null) 'pin': pin,
        if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      });
      return res;
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  /// Get QR code
  Future<void> fetchQR({double? amount}) async {
    try {
      final endpoint = amount != null ? '/wallet/qr?amount=$amount' : '/wallet/qr';
      final res = await ApiService.get(endpoint);
      if (res['success'] == true) {
        _qrImage = res['data']['qr_image'];
        notifyListeners();
      }
    } catch (e) {
      print('QR fetch error: $e');
    }
  }

  /// Lookup user by ID
  Future<Map<String, dynamic>?> lookupUser(String userId) async {
    try {
      final res = await ApiService.get('/wallet/user/$userId');
      if (res['success'] == true) {
        return res['data'];
      }
    } catch (_) {}
    return null;
  }

  /// Fetch tasks
  Future<void> fetchTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.get('/rewards/tasks');
      if (res['success'] == true) {
        _tasks = List<Map<String, dynamic>>.from(res['data']['tasks']);
        _weeklyEarnings = (res['data']['weekly_earnings'] ?? 0).toDouble();
      }
    } catch (e) {
      print('Tasks fetch error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Start a task
  Future<Map<String, dynamic>> startTask(String taskId) async {
    try {
      final res = await ApiService.post('/rewards/start/$taskId', {});
      return res;
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  /// Complete a task
  Future<Map<String, dynamic>> completeTask(String taskId) async {
    try {
      final res = await ApiService.post('/rewards/complete/$taskId', {});
      if (res['success'] == true) {
        // Update task locally
        final idx = _tasks.indexWhere((t) => t['task_id'] == taskId);
        if (idx != -1) {
          _tasks[idx]['completed'] = true;
        }
        final reward = (res['data']['reward'] ?? 0).toDouble();
        _weeklyEarnings += reward;
        notifyListeners();
      }
      return res;
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  /// Fetch leaderboard
  Future<void> fetchLeaderboard() async {
    try {
      final res = await ApiService.get('/rewards/leaderboard?limit=10');
      if (res['success'] == true) {
        _leaderboard = List<Map<String, dynamic>>.from(res['data']);
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Fetch bank status
  Future<void> fetchBankStatus() async {
    try {
      final res = await ApiService.get('/bank/status');
      if (res['success'] == true) {
        _bankStatus = res['data'];
        notifyListeners();
      }
    } catch (_) {}
  }
}
