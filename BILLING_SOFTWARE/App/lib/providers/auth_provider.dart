import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../core/api_service.dart';

class AuthProvider extends ChangeNotifier {
  String _apiKey = '';
  String _webhookSecret = '';
  String _merchantId = '';
  String _shopName = '';
  String _ownerName = '';
  String _mobileNumber = '';
  String _securityPin = '';
  String _baseUrl = AppConstants.defaultEcoWalletBaseUrl;
  bool _isConfigured = false;
  String? _authError;

  String get apiKey => _apiKey;
  String get webhookSecret => _webhookSecret;
  String get merchantId => _merchantId;
  String get shopName => _shopName;
  String get ownerName => _ownerName;
  String get mobileNumber => _mobileNumber;
  String get securityPin => _securityPin;
  bool get hasPinSet => _securityPin.isNotEmpty;
  String get baseUrl => _baseUrl;
  bool get isConfigured => _isConfigured;
  String? get authError => _authError;

  ApiService get apiService => ApiService(baseUrl: _baseUrl, apiKey: _apiKey);

  AuthProvider() {
    loadSavedCredentials();
  }

  Future<void> loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(AppConstants.keyApiKey) ?? '';
    _webhookSecret = prefs.getString(AppConstants.keyWebhookSecret) ?? '';
    _merchantId = prefs.getString(AppConstants.keyMerchantId) ?? '';
    _shopName = prefs.getString(AppConstants.keyShopName) ?? '';
    _ownerName = prefs.getString(AppConstants.keyOwnerName) ?? '';
    _mobileNumber = prefs.getString('mobile_number') ?? '';
    _securityPin = prefs.getString('security_pin') ?? '';
    _baseUrl = prefs.getString(AppConstants.keyBaseUrl) ?? AppConstants.defaultEcoWalletBaseUrl;

    _isConfigured = _apiKey.isNotEmpty || _mobileNumber.isNotEmpty;
    notifyListeners();
  }

  Future<void> saveCredentials({
    required String apiKey,
    required String webhookSecret,
    required String merchantId,
    required String shopName,
    required String ownerName,
    required String mobileNumber,
    required String securityPin,
    required String baseUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyApiKey, apiKey);
    await prefs.setString(AppConstants.keyWebhookSecret, webhookSecret);
    await prefs.setString(AppConstants.keyMerchantId, merchantId);
    await prefs.setString(AppConstants.keyShopName, shopName);
    await prefs.setString(AppConstants.keyOwnerName, ownerName);
    await prefs.setString('mobile_number', mobileNumber);
    await prefs.setString('security_pin', securityPin);
    await prefs.setString(AppConstants.keyBaseUrl, baseUrl);

    _apiKey = apiKey;
    _webhookSecret = webhookSecret;
    _merchantId = merchantId;
    _shopName = shopName;
    _ownerName = ownerName;
    _mobileNumber = mobileNumber;
    _securityPin = securityPin;
    _baseUrl = baseUrl;
    _isConfigured = true;

    notifyListeners();
  }

  Future<bool> loginWithPin(String mobile, String pin) async {
    _authError = null;
    if (_mobileNumber.isNotEmpty && _mobileNumber != mobile) {
      _authError = 'Mobile number does not match registered account';
      notifyListeners();
      return false;
    }
    if (_securityPin.isNotEmpty && _securityPin != pin) {
      _authError = 'Incorrect security PIN';
      notifyListeners();
      return false;
    }

    _mobileNumber = mobile;
    _securityPin = pin;
    _isConfigured = true;
    notifyListeners();
    return true;
  }

  Future<bool> registerMerchant({
    required String mobile,
    required String shopName,
    required String ownerName,
    required String pin,
  }) async {
    _authError = null;
    try {
      await saveCredentials(
        apiKey: 'eco_key_${DateTime.now().millisecondsSinceEpoch}',
        webhookSecret: 'whsec_${DateTime.now().millisecondsSinceEpoch}',
        merchantId: 'mch_$mobile',
        shopName: shopName,
        ownerName: ownerName,
        mobileNumber: mobile,
        securityPin: pin,
        baseUrl: _baseUrl,
      );
      return true;
    } catch (e) {
      _authError = e.toString();
      notifyListeners();
      return false;
    }
  }

  bool verifyPin(String enteredPin) {
    if (!hasPinSet) return true;
    return _securityPin == enteredPin;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _apiKey = '';
    _webhookSecret = '';
    _merchantId = '';
    _shopName = '';
    _ownerName = '';
    _mobileNumber = '';
    _securityPin = '';
    _isConfigured = false;
    notifyListeners();
  }
}
