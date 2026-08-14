import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://eco-wallet.onrender.com/api';

  static String? _accessToken;
  static String? _refreshToken;
  static String? _backupRefreshToken;
  static Future<bool>? _activeRefreshFuture;

  static Future<void> setTokens(String access, String refresh, [String? backupRefresh]) async {
    _accessToken = access;
    _refreshToken = refresh;
    if (backupRefresh != null && backupRefresh.isNotEmpty) {
      _backupRefreshToken = backupRefresh;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
    if (_backupRefreshToken != null) {
      await prefs.setString('backup_refresh_token', _backupRefreshToken!);
    }
  }

  static Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
    _backupRefreshToken = prefs.getString('backup_refresh_token');
  }

  static Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _backupRefreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('backup_refresh_token');
  }

  static bool get hasToken => _accessToken != null;

  static Map<String, String> _headers({bool auth = true}) {
    final headers = {'Content-Type': 'application/json'};
    if (auth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> _handleResponse(http.Response res) async {
    try {
      final data = jsonDecode(res.body);
      if (res.statusCode == 401 && (_refreshToken != null || _backupRefreshToken != null)) {
        final refreshed = await tryRefreshTokenLoop();
        if (refreshed) {
          return {'_retry': true};
        }
      }
      return data;
    } catch (_) {
      if (res.statusCode == 401 && (_refreshToken != null || _backupRefreshToken != null)) {
        final refreshed = await tryRefreshTokenLoop();
        if (refreshed) {
          return {'_retry': true};
        }
      }
      return {'success': false, 'message': 'Unexpected response format'};
    }
  }

  static Future<bool> tryRefreshTokenLoop() async {
    if (_activeRefreshFuture != null) {
      return await _activeRefreshFuture!;
    }
    _activeRefreshFuture = _performTokenRefreshLoop();
    try {
      final result = await _activeRefreshFuture!;
      _activeRefreshFuture = null;
      return result;
    } catch (_) {
      _activeRefreshFuture = null;
      return false;
    }
  }

  static Future<bool> _performTokenRefreshLoop() async {
    final tokensToTry = <String>[];
    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      tokensToTry.add(_refreshToken!);
    }
    if (_backupRefreshToken != null && _backupRefreshToken!.isNotEmpty && _backupRefreshToken != _refreshToken) {
      tokensToTry.add(_backupRefreshToken!);
    }

    for (final token in tokensToTry) {
      try {
        final res = await http.post(
          Uri.parse('$baseUrl/auth/refresh'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': token}),
        ).timeout(const Duration(seconds: 15));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['success'] == true && data['data'] != null) {
            final newAccess = data['data']['accessToken'] ?? '';
            final newRefresh = data['data']['refreshToken'] ?? token;
            final newBackup = data['data']['backupRefreshToken'] ?? _backupRefreshToken;
            if (newAccess.isNotEmpty) {
              await setTokens(newAccess, newRefresh, newBackup);
              return true;
            }
          }
        }
      } catch (_) {}
    }

    await clearTokens();
    return false;
  }

  static Future<Map<String, dynamic>> get(String path) async {
    final res = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers(),
    );
    final data = await _handleResponse(res);
    if (data.containsKey('_retry')) {
      final retry = await http.get(Uri.parse('$baseUrl$path'), headers: _headers());
      try {
        return jsonDecode(retry.body);
      } catch (_) {
        return {'success': false};
      }
    }
    return data;
  }

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    final data = await _handleResponse(res);
    if (data.containsKey('_retry')) {
      final retry = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers(),
        body: jsonEncode(body),
      );
      try {
        return jsonDecode(retry.body);
      } catch (_) {
        return {'success': false};
      }
    }
    return data;
  }

  static Future<Map<String, dynamic>> put(String path, [Map<String, dynamic>? body]) async {
    final res = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    final data = await _handleResponse(res);
    if (data.containsKey('_retry')) {
      final retry = await http.put(
        Uri.parse('$baseUrl$path'),
        headers: _headers(),
        body: body != null ? jsonEncode(body) : null,
      );
      try {
        return jsonDecode(retry.body);
      } catch (_) {
        return {'success': false};
      }
    }
    return data;
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final res = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: _headers(),
    );
    final data = await _handleResponse(res);
    if (data.containsKey('_retry')) {
      final retry = await http.delete(
        Uri.parse('$baseUrl$path'),
        headers: _headers(),
      );
      try {
        return jsonDecode(retry.body);
      } catch (_) {
        return {'success': false};
      }
    }
    return data;
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password, {String? referralCode}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers(auth: false),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        if (referralCode != null && referralCode.isNotEmpty) 'referral_code': referralCode
      }),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(auth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updateProfile(String name, String phone) async {
    return await put('/auth/profile', {'name': name, 'phone': phone});
  }

  static Future<Map<String, dynamic>> setPin(String pin, {String? currentPin}) async {
    final body = {'pin': pin};
    if (currentPin != null) body['current_pin'] = currentPin;
    return await post('/auth/set-pin', body);
  }

  static Future<Map<String, dynamic>> removePin(String currentPin) async {
    return await post('/auth/remove-pin', {'current_pin': currentPin});
  }

  static Future<Map<String, dynamic>> getNotifications({int page = 1, int limit = 20}) async {
    return await get('/notifications?page=$page&limit=$limit');
  }

  static Future<Map<String, dynamic>> markNotificationRead(String id) async {
    return await put('/notifications/$id/read');
  }

  static Future<Map<String, dynamic>> markAllNotificationsRead() async {
    return await put('/notifications/read-all');
  }

  static Future<Map<String, dynamic>> registerFcmToken(String token) async {
    if (!hasToken) return {'success': false, 'error': 'No authentication token'};
    return await post('/notifications/register-token', {'token': token});
  }
}

