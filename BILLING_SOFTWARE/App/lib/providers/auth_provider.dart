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
  String _gstin = '';
  String _address = '';
  String _upiId = '';
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
  String get gstin => _gstin;
  String get address => _address;
  String get upiId => _upiId;
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
    _gstin = prefs.getString('shop_gstin') ?? '';
    _address = prefs.getString('shop_address') ?? '';
    _upiId = prefs.getString('shop_upi_id') ?? '';
    _baseUrl = prefs.getString(AppConstants.keyBaseUrl) ?? AppConstants.defaultEcoWalletBaseUrl;

    _isConfigured = _apiKey.isNotEmpty || _mobileNumber.isNotEmpty;
    notifyListeners();

    if (_baseUrl.isNotEmpty) {
      try {
        final profile = await apiService.getMerchantProfile();
        if (profile.isNotEmpty) {
          if (profile['business_name'] != null && profile['business_name'].toString().isNotEmpty) {
            _shopName = profile['business_name'];
            await prefs.setString(AppConstants.keyShopName, _shopName);
          }
          if (profile['owner_name'] != null && profile['owner_name'].toString().isNotEmpty) {
            _ownerName = profile['owner_name'];
            await prefs.setString(AppConstants.keyOwnerName, _ownerName);
          }
          if (profile['gstin'] != null) {
            _gstin = profile['gstin'];
            await prefs.setString('shop_gstin', _gstin);
          }
          if (profile['address'] != null) {
            _address = profile['address'];
            await prefs.setString('shop_address', _address);
          }
          if (profile['upi_id'] != null) {
            _upiId = profile['upi_id'];
            await prefs.setString('shop_upi_id', _upiId);
          }
          notifyListeners();
        }
      } catch (_) {}
    }
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
    String gstin = '',
    String address = '',
    String upiId = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyApiKey, apiKey);
    await prefs.setString(AppConstants.keyWebhookSecret, webhookSecret);
    await prefs.setString(AppConstants.keyMerchantId, merchantId);
    await prefs.setString(AppConstants.keyShopName, shopName);
    await prefs.setString(AppConstants.keyOwnerName, ownerName);
    await prefs.setString('mobile_number', mobileNumber);
    await prefs.setString('security_pin', securityPin);
    await prefs.setString('shop_gstin', gstin);
    await prefs.setString('shop_address', address);
    await prefs.setString('shop_upi_id', upiId);
    await prefs.setString(AppConstants.keyBaseUrl, baseUrl);

    _apiKey = apiKey;
    _webhookSecret = webhookSecret;
    _merchantId = merchantId;
    _shopName = shopName;
    _ownerName = ownerName;
    _mobileNumber = mobileNumber;
    _securityPin = securityPin;
    _gstin = gstin;
    _address = address;
    _upiId = upiId;
    _baseUrl = baseUrl;
    _isConfigured = true;
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String shopName,
    required String ownerName,
    required String mobileNumber,
    required String gstin,
    required String address,
    String upiId = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyShopName, shopName);
    await prefs.setString(AppConstants.keyOwnerName, ownerName);
    await prefs.setString('mobile_number', mobileNumber);
    await prefs.setString('shop_gstin', gstin);
    await prefs.setString('shop_address', address);
    await prefs.setString('shop_upi_id', upiId);

    _shopName = shopName;
    _ownerName = ownerName;
    _mobileNumber = mobileNumber;
    _gstin = gstin;
    _address = address;
    _upiId = upiId;
    notifyListeners();

    try {
      await apiService.updateMerchantProfile(
        shopName: shopName,
        ownerName: ownerName,
        mobileNumber: mobileNumber,
        gstin: gstin,
        address: address,
        upiId: upiId,
      );
      return true;
    } catch (_) {
      return true;
    }
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
    String gstin = '',
    String address = '',
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
        gstin: gstin,
        address: address,
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
    _gstin = '';
    _address = '';
    _isConfigured = false;
    notifyListeners();
  }
}
