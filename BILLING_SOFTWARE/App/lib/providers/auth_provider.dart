import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

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

  bool verifyPin(String enteredPin) {
    if (!hasPinSet) return true;
    return _securityPin == enteredPin;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyApiKey);
    await prefs.remove(AppConstants.keyMerchantId);
    await prefs.remove('mobile_number');
    await prefs.remove(AppConstants.keyShopName);
    await prefs.remove(AppConstants.keyOwnerName);
    _apiKey = '';
    _merchantId = '';
    _mobileNumber = '';
    _shopName = '';
    _ownerName = '';
    _isConfigured = false;
    notifyListeners();
  }
}
