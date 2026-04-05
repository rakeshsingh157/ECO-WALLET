/// ECO Wallet — API Service
/// Handles all HTTP communication with the Node.js backend.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {

  static const String baseUrl = 'https://eco-wallet.onrender.com/api';

  static String? _accessToken;
  static String? _refreshToken;

  // ─── Token Management ─────────────────────────────────
  static Future<void> setTokens(String access, String refresh) async {
    _accessToken = access;
    _refreshToken = refresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  static Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  static Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  static bool get hasToken => _accessToken != null;

  // ─── HTTP Helpers ─────────────────────────────────────
  static Map<String, String> _headers({bool auth = true}) {
    final headers = {'Content-Type': 'application/json'};
    if (auth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> _handleResponse(http.Response res) async {
    final data = jsonDecode(res.body);

    // If 401, try refresh
    if (res.statusCode == 401 && _refreshToken != null) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        return {'_retry': true};
      }
    }

    return data;
  }

  static Future<bool> _tryRefresh() async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          await setTokens(
            data['data']['accessToken'],
            data['data']['refreshToken'],
          );
          return true;
        }
      }
    } catch (_) {}
    await clearTokens();
    return false;
  }

  // ─── Generic Request Methods ──────────────────────────
  static Future<Map<String, dynamic>> get(String path) async {
    final res = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers(),
    );
    final data = await _handleResponse(res);
    if (data.containsKey('_retry')) {
      final retry = await http.get(Uri.parse('$baseUrl$path'), headers: _headers());
      return jsonDecode(retry.body);
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
      return jsonDecode(retry.body);
    }
    return data;
  }

  static Future<Map<String, dynamic>> put(String path, [Map<String, dynamic>? body]) async {
    final res = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return jsonDecode(res.body);
  }

  // ─── Auth API ─────────────────────────────────────────
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

  // ─── Profile & Settings ───────────────────────────────
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

  // ─── Notifications ────────────────────────────────────
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
