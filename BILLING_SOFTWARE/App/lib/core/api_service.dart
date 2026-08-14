import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  final String baseUrl;
  final String apiKey;

  ApiService({
    required this.baseUrl,
    required this.apiKey,
  });

  String get _cleanBase => baseUrl.endsWith('/api') ? baseUrl : '$baseUrl/api';

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        "X-API-Key": apiKey,
      };

  // ==================== AUTHENTICATION ====================

  /// Sign Up New Merchant Store
  Future<Map<String, dynamic>> signupMerchant({
    required String mobileNumber,
    required String shopName,
    required String ownerName,
    required String securityPin,
  }) async {
    final url = Uri.parse("$_cleanBase/merchant/signup");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "mobile_number": mobileNumber,
          "shop_name": shopName,
          "owner_name": ownerName,
          "security_pin": securityPin,
        }),
      ).timeout(const Duration(seconds: 12));

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {"success": false, "message": "Connection error: ${e.toString()}"};
    }
  }

  /// Login Existing Merchant
  Future<Map<String, dynamic>> loginMerchant({
    required String mobileNumber,
    required String securityPin,
  }) async {
    final url = Uri.parse("$_cleanBase/merchant/login");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "mobile_number": mobileNumber,
          "security_pin": securityPin,
        }),
      ).timeout(const Duration(seconds: 12));

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {"success": false, "message": "Connection error: ${e.toString()}"};
    }
  }

  // ==================== PRODUCTS / INVENTORY ====================

  /// Fetch all products from MongoDB Atlas
  Future<List<Product>> getProducts() async {
    final url = Uri.parse("$_cleanBase/products");
    try {
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["data"] is List) {
          return (data["data"] as List).map((p) => Product(
            id: p["product_id"] ?? p["_id"] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            name: p["name"] ?? "Item",
            price: (p["price"] as num?)?.toDouble() ?? 0.0,
            category: p["category"] ?? "General",
            unit: p["unit"] ?? "pcs",
            stock: (p["stock"] as num?)?.toInt() ?? 10,
            icon: p["icon"] ?? "box",
          )).toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Add new product to MongoDB Atlas
  Future<bool> addProduct(Product product) async {
    final url = Uri.parse("$_cleanBase/products");
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "product_id": product.id,
          "name": product.name,
          "price": product.price,
          "category": product.category,
          "unit": product.unit,
          "stock": product.stock,
          "icon": product.icon,
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Delete product from MongoDB Atlas
  Future<bool> deleteProduct(String productId) async {
    final url = Uri.parse("$_cleanBase/products/$productId");
    try {
      final response = await http.delete(url, headers: _headers).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ==================== BILLS / SALES ====================

  /// Fetch all bills and sales summary from MongoDB Atlas
  Future<Map<String, dynamic>> getBills() async {
    final url = Uri.parse("$_cleanBase/bills");
    try {
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {"success": false, "todaySales": 0, "todayBillCount": 0, "data": []};
    } catch (_) {
      return {"success": false, "todaySales": 0, "todayBillCount": 0, "data": []};
    }
  }

  /// Save completed bill to MongoDB Atlas
  Future<bool> saveBill({
    required String billId,
    required List<dynamic> items,
    required double totalAmount,
    required String paymentMode,
    String? customerName,
    String? customerPhone,
    String? khataCustomerId,
  }) async {
    final url = Uri.parse("$_cleanBase/bills");
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

  // ==================== KHATA BOOK ====================

  /// Fetch Khata customers from MongoDB Atlas
  Future<List<Map<String, dynamic>>> getKhataCustomers() async {
    final url = Uri.parse("$_cleanBase/khata");
    try {
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["data"] is List) {
          return List<Map<String, dynamic>>.from(data["data"]);
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Add new Khata customer to MongoDB Atlas
  Future<bool> addKhataCustomer({
    required String customerId,
    required String name,
    required String phone,
    String? address,
    String? aadhaarNumber,
    double dueAmount = 0.0,
  }) async {
    final url = Uri.parse("$_cleanBase/khata");
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "customer_id": customerId,
          "name": name,
          "phone": phone,
          "address": address,
          "aadhaar_number": aadhaarNumber,
          "due_amount": dueAmount,
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Record Khata transaction (credit/payment)
  Future<bool> recordKhataTransaction({
    required String customerId,
    required String type, // 'credit' or 'payment'
    required double amount,
  }) async {
    final url = Uri.parse("$_cleanBase/khata/$customerId/transaction");
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "type": type,
          "amount": amount,
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ==================== STAFF MEMBERS ====================

  /// Fetch staff members from MongoDB Atlas
  Future<List<Map<String, dynamic>>> getStaffMembers() async {
    final url = Uri.parse("$_cleanBase/staff");
    try {
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["data"] is List) {
          return List<Map<String, dynamic>>.from(data["data"]);
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Add staff member to MongoDB Atlas
  Future<bool> addStaffMember({
    required String memberId,
    required String name,
    required String phone,
    required String role,
    String pin = "0000",
  }) async {
    final url = Uri.parse("$_cleanBase/staff");
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "member_id": memberId,
          "name": name,
          "phone": phone,
          "role": role,
          "pin": pin,
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // ==================== MERCHANT PAYMENTS ====================

  /// Create payment request directly on ECO Wallet merchant backend API
  Future<Map<String, dynamic>> createPayment({
    required String orderId,
    required double amount,
    String? description,
  }) async {
    final url = Uri.parse("$_cleanBase/merchant/create-payment");
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
    final url = Uri.parse("$_cleanBase/merchant/payment/$paymentId/status");
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
}
