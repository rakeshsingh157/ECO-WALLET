import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://eco-wallet.onrender.com/api';
  static const Duration defaultTimeout = Duration(seconds: 25);

  static String? _accessToken;
  static String? _refreshToken;
  static String? _backupRefreshToken;
  static Completer<bool>? _refreshCompleter;

  static Future<void> setTokens(String access, String refresh, {String? backupRefresh}) async {
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

  static Future<bool> _tryRefresh() async {
    if (_refreshCompleter != null) {
      return await _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    if (_refreshToken == null && _backupRefreshToken == null) {
      await loadTokens();
    }

    final tokenCandidate = _refreshToken ?? _backupRefreshToken;
    if (tokenCandidate == null) {
      _refreshCompleter!.complete(false);
      _refreshCompleter = null;
      return false;
    }

    bool success = false;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refreshToken': tokenCandidate,
          'backupRefreshToken': _backupRefreshToken,
        }),
      ).timeout(defaultTimeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] != null) {
          final newAccess = data['data']['accessToken'];
          final newRefresh = data['data']['refreshToken'] ?? tokenCandidate;
          final newBackup = data['data']['backupRefreshToken'] ?? _backupRefreshToken;
          if (newAccess != null) {
            await setTokens(newAccess, newRefresh, backupRefresh: newBackup);
            success = true;
          }
        }
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        if (_backupRefreshToken != null && tokenCandidate != _backupRefreshToken) {
          final backupRes = await http.post(
            Uri.parse('$baseUrl/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': _backupRefreshToken}),
          ).timeout(defaultTimeout);

          if (backupRes.statusCode == 200) {
            final data = jsonDecode(backupRes.body);
            if (data['success'] == true && data['data'] != null) {
              final newAccess = data['data']['accessToken'];
              final newRefresh = data['data']['refreshToken'];
              final newBackup = data['data']['backupRefreshToken'];
              if (newAccess != null && newRefresh != null) {
                await setTokens(newAccess, newRefresh, backupRefresh: newBackup);
                success = true;
              }
            }
          }
        }
        if (!success) {
          await clearTokens();
        }
      }
    } catch (_) {}

    _refreshCompleter!.complete(success);
    _refreshCompleter = null;
    return success;
  }

  static Future<Map<String, dynamic>> _executeRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');

    Future<http.Response> makeCall() {
      final headers = _headers(auth: auth);
      switch (method.toUpperCase()) {
        case 'GET':
          return http.get(uri, headers: headers).timeout(defaultTimeout);
        case 'POST':
          return http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null).timeout(defaultTimeout);
        case 'PUT':
          return http.put(uri, headers: headers, body: body != null ? jsonEncode(body) : null).timeout(defaultTimeout);
        case 'DELETE':
          return http.delete(uri, headers: headers).timeout(defaultTimeout);
        default:
          return http.get(uri, headers: headers).timeout(defaultTimeout);
      }
    }

    try {
      final res = await makeCall();
      if (res.statusCode == 401 && auth) {
        final refreshed = await _tryRefresh();
        if (refreshed) {
          final retryRes = await makeCall();
          final text = retryRes.body.trim();
          if (text.startsWith('{') || text.startsWith('[')) {
            return jsonDecode(text);
          }
          return {'success': false, 'message': 'Invalid response format'};
        }
      }

      final text = res.body.trim();
      if (text.startsWith('{') || text.startsWith('[')) {
        return jsonDecode(text);
      }
      return {'success': false, 'message': 'Invalid server response (${res.statusCode})'};
    } catch (e) {
      return {'success': false, 'message': 'Network timeout or connection error'};
    }
  }

  static Future<Map<String, dynamic>> get(String path) async {
    return await _executeRequest('GET', path);
  }

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    return await _executeRequest('POST', path, body: body);
  }

  static Future<Map<String, dynamic>> put(String path, [Map<String, dynamic>? body]) async {
    return await _executeRequest('PUT', path, body: body);
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    return await _executeRequest('DELETE', path);
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
    ).timeout(defaultTimeout);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(auth: false),
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(defaultTimeout);
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
