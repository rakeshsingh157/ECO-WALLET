import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  final String apiKey;

  ApiService({
    required this.baseUrl,
    required this.apiKey,
  });

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        "X-API-Key": apiKey,
      };

  /// Create payment request directly on ECO Wallet merchant backend API
  Future<Map<String, dynamic>> createPayment({
    required String orderId,
    required double amount,
    String? description,
  }) async {
    final cleanBaseUrl = baseUrl.endsWith('/api') ? baseUrl : '$baseUrl/api';
    final url = Uri.parse("$cleanBaseUrl/merchant/create-payment");

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "order_id": orderId,
          "amount": amount,
          "description": description ?? "Dukaan Dost Bill #$orderId",
        }),
      ).timeout(const Duration(seconds: 15));

      final bodyText = response.body.trim();
      if (bodyText.startsWith('{') || bodyText.startsWith('[')) {
        final data = jsonDecode(bodyText);
        if (response.statusCode == 200 || response.statusCode == 201) {
          return data;
        } else {
          return {
            "success": false,
            "message": data["message"] ?? "Server error (${response.statusCode})",
          };
        }
      }
      return {"success": false, "message": "Invalid response format from server"};
    } catch (e) {
      return {
        "success": false,
        "message": "Connection error: ${e.toString().replaceAll('Instance of ', '')}",
      };
    }
  }

  /// Poll status of a merchant payment directly from backend API
  Future<Map<String, dynamic>> checkPaymentStatus(String paymentId) async {
    final cleanBaseUrl = baseUrl.endsWith('/api') ? baseUrl : '$baseUrl/api';
    final url = Uri.parse("$cleanBaseUrl/merchant/payment/$paymentId/status");

    try {
      final response = await http.get(
        url,
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      final bodyText = response.body.trim();
      if (bodyText.startsWith('{') || bodyText.startsWith('[')) {
        final data = jsonDecode(bodyText);
        if (response.statusCode == 200) {
          return data;
        }
      }
      return {
        "success": false,
        "payment": {"payment_id": paymentId, "status": "pending"}
      };
    } catch (_) {
      return {
        "success": false,
        "payment": {"payment_id": paymentId, "status": "pending"}
      };
    }
  }

  /// Save any bill (Cash, UPI, Khata, ECO Wallet) directly to MongoDB Atlas bills collection
  Future<bool> saveBill({
    required String billId,
    required List<dynamic> items,
    required double totalAmount,
    required String paymentMode,
    String? customerName,
    String? customerPhone,
    String? khataCustomerId,
  }) async {
    final cleanBaseUrl = baseUrl.endsWith('/api') ? baseUrl : '$baseUrl/api';
    final url = Uri.parse("$cleanBaseUrl/bills");

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "bill_id": billId,
          "items": items.map((item) => {
            "product_id": item.product.id,
            "name": item.product.name,
            "price": item.product.price,
            "quantity": item.quantity,
          }).toList(),
          "total_amount": totalAmount,
          "payment_mode": paymentMode,
          "customer_name": customerName ?? "Counter Customer",
          "customer_phone": customerPhone,
          "khata_customer_id": khataCustomerId,
          "status": paymentMode == "pending" ? "pending" : "completed",
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
