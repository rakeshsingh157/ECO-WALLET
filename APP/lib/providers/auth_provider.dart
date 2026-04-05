/// ECO Wallet — Auth State Provider
import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/firebase_config.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _user;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;
  String get userId => _user?['user_id'] ?? '';
  String get userName => _user?['name'] ?? '';
  String get userEmail => _user?['email'] ?? '';
  double get balance => (_user?['balance'] ?? 0).toDouble();
  String get role => _user?['role'] ?? 'user';
  bool get isAdmin => role == 'admin';

  /// Check if user is already logged in (from saved token)
  Future<bool> checkAuth() async {
    await ApiService.loadTokens();
    if (!ApiService.hasToken) return false;

    try {
      final res = await ApiService.get('/auth/me');
      if (res['success'] == true) {
        _user = res['data'];
        _isLoggedIn = true;
        notifyListeners();
        return true;
      }
    } catch (_) {}

    await ApiService.clearTokens();
    return false;
  }

  /// Register a new account
  Future<bool> register(String name, String email, String password, {String? referralCode}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.register(name, email, password, referralCode: referralCode);
      if (res['success'] == true) {
        _user = res['data']['user'];
        _isLoggedIn = true;
        await ApiService.setTokens(
          res['data']['accessToken'],
          res['data']['refreshToken'],
        );
        await FirebaseConfig.registerToken();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Registration failed';
      }
    } catch (e) {
      _error = 'Connection error. Is the server running?';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.login(email, password);
      if (res['success'] == true) {
        _user = res['data']['user'];
        _isLoggedIn = true;
        await ApiService.setTokens(
          res['data']['accessToken'],
          res['data']['refreshToken'],
        );
        await FirebaseConfig.registerToken();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = res['message'] ?? 'Login failed';
      }
    } catch (e) {
      _error = 'Connection error. Is the server running?';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    try {
      final res = await ApiService.get('/auth/me');
      if (res['success'] == true) {
        _user = res['data'];
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Fetch complete profile with stats
  Future<void> fetchProfile() async {
    try {
      final res = await ApiService.get('/auth/profile');
      if (res['success'] == true) {
        _user = res['data'];
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Update balance locally (after a transfer)
  void updateBalance(double newBalance) {
    if (_user != null) {
      _user!['balance'] = newBalance;
      notifyListeners();
    }
  }

  /// Logout
  Future<void> logout() async {
    await ApiService.clearTokens();
    _user = null;
    _isLoggedIn = false;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
