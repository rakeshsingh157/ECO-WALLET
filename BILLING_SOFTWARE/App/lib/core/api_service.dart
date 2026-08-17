import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/customer.dart';
import '../models/supplier.dart';
import '../models/expense.dart';
import '../models/notification_item.dart';

class ApiService {
  final String baseUrl;
  final String apiKey;

  static const Duration requestTimeout = Duration(seconds: 15);

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
      ).timeout(requestTimeout);

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: ${e.toString()}"};
    }
  }

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
      ).timeout(requestTimeout);

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": "Connection error: ${e.toString()}"};
    }
  }

  // ==================== PRODUCTS / INVENTORY ====================

  Future<List<Product>> getProducts() async {
    final url = Uri.parse("$_cleanBase/products");
    try {
      final response = await http.get(url, headers: _headers).timeout(requestTimeout);
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
            lowStockAlert: (p["min_stock_alert"] as num?)?.toInt() ?? 5,
            icon: p["icon"] ?? "box",
            barcode: p["barcode"],
          )).toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

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
          "min_stock_alert": product.lowStockAlert,
          "icon": product.icon,
          "barcode": product.barcode,
        }),
      ).timeout(requestTimeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    final url = Uri.parse("$_cleanBase/products/${product.id}");
    try {
      final response = await http.put(
        url,
        headers: _headers,
        body: jsonEncode({
          "name": product.name,
          "price": product.price,
          "category": product.category,
          "unit": product.unit,
          "stock": product.stock,
          "min_stock_alert": product.lowStockAlert,
          "barcode": product.barcode,
        }),
      ).timeout(requestTimeout);

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    final url = Uri.parse("$_cleanBase/products/$productId");
    try {
      final response = await http.delete(url, headers: _headers).timeout(requestTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ==================== BILLS / SALES ====================

  Future<Map<String, dynamic>> getBills() async {
    final url = Uri.parse("$_cleanBase/bills");
    try {
      final response = await http.get(url, headers: _headers).timeout(requestTimeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {"success": false, "todaySales": 0, "todayBillCount": 0, "data": []};
    } catch (_) {
      return {"success": false, "todaySales": 0, "todayBillCount": 0, "data": []};
    }
  }

  Future<bool> saveBill({
    required String billId,
    required List<dynamic> items,
    required double totalAmount,
    required String paymentMode,
    String? customerName,
    String? customerPhone,
    String? khataCustomerId,
    String? shopName,
    String? ownerName,
    String? shopPhone,
    String? shopAddress,
    String? shopGstin,
    String? merchantId,
  }) async {
    final url = Uri.parse("$_cleanBase/bills");
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "bill_id": billId,
          "merchant_id": merchantId,
          "shop_name": shopName,
          "owner_name": ownerName,
          "shop_phone": shopPhone,
          "shop_address": shopAddress,
          "shop_gstin": shopGstin,
          "items": items.map((item) => {
            "product_id": item.product.id,
            "name": item.product.name,
            "price": item.product.price,
            "quantity": item.quantity,
            "unit": item.product.unit,
          }).toList(),
          "total_amount": totalAmount,
          "payment_mode": paymentMode,
          "customer_name": customerName ?? "Counter Customer",
          "customer_phone": customerPhone,
          "khata_customer_id": khataCustomerId,
          "status": paymentMode == "pending" ? "pending" : "completed",
        }),
      ).timeout(requestTimeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> returnBill({
    required String billId,
    String returnType = 'full',
    List<Map<String, dynamic>>? returnedItems,
    String? reason,
    String? refundMode,
  }) async {
    final url = Uri.parse("$_cleanBase/bills/return");
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "bill_id": billId,
          "return_type": returnType,
          "returned_items": returnedItems ?? [],
          "reason": reason ?? "Customer Return",
          "refund_mode": refundMode ?? "cash",
        }),
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final err = jsonDecode(response.body);
        return {"success": false, "message": err["message"] ?? "Failed to process return"};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }


  Future<List<Customer>> getCustomers() async {
    final url = Uri.parse("$_cleanBase/customers");
    try {
      final response = await http.get(url, headers: _headers).timeout(requestTimeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["data"] is List) {
          return (data["data"] as List).map((c) => Customer(
            id: c["customer_id"] ?? c["id"] ?? c["_id"] ?? "c_${DateTime.now().millisecondsSinceEpoch}",
            name: c["name"] ?? "Customer",
            phone: c["phone"] ?? "",
            email: c["email"] ?? "",
            address: c["address"] ?? "",
            aadhaarNumber: c["aadhaar_number"] ?? c["aadhaarNumber"] ?? "",
            dueAmount: (c["due_amount"] ?? c["dueAmount"] as num?)?.toDouble() ?? 0.0,
            totalSpent: (c["total_spent"] ?? c["totalSpent"] as num?)?.toDouble() ?? 0.0,
            totalOrders: (c["total_orders"] ?? c["totalOrders"] as num?)?.toInt() ?? 0,
          )).toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> addCustomer(Customer customer) async {
    final url = Uri.parse("$_cleanBase/customers");
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "customer_id": customer.id,
          "name": customer.name,
          "phone": customer.phone,
          "email": customer.email,
          "address": customer.address,
          "aadhaar_number": customer.aadhaarNumber,
          "due_amount": customer.dueAmount,
        }),
      ).timeout(requestTimeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getCustomerTransactions(String customerId) async {
    final url = Uri.parse("$_cleanBase/customers/$customerId/transactions");
    try {
      final response = await http.get(url, headers: _headers).timeout(requestTimeout);
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

  Future<bool> recordCustomerPayment(
    String customerId,
    double amount, {
    String? note,
    String? paymentMode,
  }) async {
    final url = Uri.parse("$_cleanBase/customers/$customerId/payment");
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "amount": amount,
          "note": note ?? "Khata cash settlement",
          "payment_mode": paymentMode ?? "cash",
        }),
      ).timeout(requestTimeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addCustomerCredit(
    String customerId,
    double amount, {
    String? note,
    String? billId,
    String? paymentMode,
  }) async {
    final url = Uri.parse("$_cleanBase/customers/$customerId/credit");
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "amount": amount,
          "note": note ?? "Khata credit (Udhar)",
          "bill_id": billId,
          "payment_mode": paymentMode ?? "khata",
        }),
      ).timeout(requestTimeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

 
  Future<List<Supplier>> getSuppliers() async {
    final url = Uri.parse("$_cleanBase/suppliers");
    try {
      final response = await http.get(url, headers: _headers).timeout(requestTimeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["data"] is List) {
          return (data["data"] as List).map((s) => Supplier(
            id: s["supplier_id"] ?? s["id"] ?? s["_id"] ?? "sup_${DateTime.now().millisecondsSinceEpoch}",
            name: s["name"] ?? "Vendor",
            companyName: s["company_name"] ?? s["companyName"] ?? "Distributor",
            phone: s["phone"] ?? "",
            email: s["email"],
            address: s["address"] ?? "",
            gstin: s["gstin"] ?? "",
            pendingPayment: (s["pending_payment"] ?? s["pendingPayment"] as num?)?.toDouble() ?? 0.0,
            ordersSupplied: (s["orders_supplied"] ?? s["ordersSupplied"] as num?)?.toInt() ?? 0,
          )).toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> addSupplier(Supplier supplier) async {
    final url = Uri.parse("$_cleanBase/suppliers");
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "supplier_id": supplier.id,
          "name": supplier.name,
          "company_name": supplier.companyName,
          "phone": supplier.phone,
          "email": supplier.email,
          "address": supplier.address,
          "gstin": supplier.gstin,
        }),
      ).timeout(requestTimeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> recordSupplierPayment(String supplierId, double amount) async {
    final url = Uri.parse("$_cleanBase/suppliers/$supplierId/pay");
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({"amount": amount}),
      ).timeout(requestTimeout);

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getSupplierPurchases(String supplierId) async {
    final url = Uri.parse("$_cleanBase/suppliers/$supplierId/purchases");
    try {
      final response = await http.get(url, headers: _headers).timeout(requestTimeout);
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

 
  Future<List<Expense>> getExpenses({String? period, String? category}) async {
    final queryParams = <String, String>{};
    if (period != null) queryParams["period"] = period;
    if (category != null) queryParams["category"] = category;

    final uri = Uri.parse("$_cleanBase/expenses").replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    try {
      final response = await http.get(uri, headers: _headers).timeout(requestTimeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["data"] is List) {
          return (data["data"] as List).map((e) => Expense(
            id: e["expense_id"] ?? e["id"] ?? e["_id"] ?? "exp_${DateTime.now().millisecondsSinceEpoch}",
            title: e["title"] ?? "Expense",
            amount: (e["amount"] as num?)?.toDouble() ?? 0.0,
            category: e["category"] ?? "Utilities",
            paymentMode: e["payment_mode"] ?? e["paymentMode"] ?? "Cash",
            notes: e["notes"] ?? "",
            date: e["date"] != null ? DateTime.parse(e["date"]) : DateTime.now(),
          )).toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> addExpense(Expense expense) async {
    final url = Uri.parse("$_cleanBase/expenses");
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "expense_id": expense.id,
          "title": expense.title,
          "amount": expense.amount,
          "category": expense.category,
          "payment_mode": expense.paymentMode,
          "notes": expense.notes,
        }),
      ).timeout(requestTimeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteExpense(String expenseId) async {
    final url = Uri.parse("$_cleanBase/expenses/$expenseId");
    try {
      final response = await http.delete(url, headers: _headers).timeout(requestTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }


  Future<Map<String, dynamic>> getReportSummary() async {
    final url = Uri.parse("$_cleanBase/reports/summary");
    try {
      final response = await http.get(url, headers: _headers).timeout(requestTimeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["data"] != null) {
          return data["data"];
        }
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getTopProducts() async {
    final url = Uri.parse("$_cleanBase/reports/top-products");
    try {
      final response = await http.get(url, headers: _headers).timeout(requestTimeout);
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


  Future<List<NotificationItem>> getNotifications() async {
    final url = Uri.parse("$_cleanBase/notifications");
    try {
      final response = await http.get(url, headers: _headers).timeout(requestTimeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["data"] is List) {
          return (data["data"] as List).map((n) => NotificationItem(
            id: n["id"] ?? n["notification_id"] ?? "notif_${DateTime.now().millisecondsSinceEpoch}",
            title: n["title"] ?? "Alert",
            message: n["message"] ?? "",
            type: n["type"] ?? "info",
            isRead: n["isRead"] ?? n["is_read"] ?? false,
            timestamp: n["createdAt"] != null ? DateTime.parse(n["createdAt"]) : DateTime.now(),
          )).toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> markNotificationRead(String id) async {
    final url = Uri.parse("$_cleanBase/notifications/$id/read");
    try {
      final response = await http.post(url, headers: _headers).timeout(requestTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markAllNotificationsRead() async {
    final url = Uri.parse("$_cleanBase/notifications/read-all");
    try {
      final response = await http.post(url, headers: _headers).timeout(requestTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }


  Future<Map<String, dynamic>> exportBackup() async {
    final url = Uri.parse("$_cleanBase/backup/export");
    try {
      final response = await http.get(url, headers: _headers).timeout(requestTimeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {"success": false, "message": "Failed to export backup"};
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  Future<Map<String, dynamic>> cloudSync() async {
    final url = Uri.parse("$_cleanBase/backup/cloud-sync");
    try {
      final response = await http.post(url, headers: _headers).timeout(requestTimeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {"success": false, "message": "Cloud sync failed"};
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  Future<Map<String, dynamic>> restoreBackup(Map<String, dynamic> backup) async {
    final url = Uri.parse("$_cleanBase/backup/restore");
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({"backup": backup}),
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {"success": false, "message": "Failed to restore database"};
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }


  Future<List<Map<String, dynamic>>> getStaffMembers() async {
    final url = Uri.parse("$_cleanBase/staff");
    try {
      final response = await http.get(url, headers: _headers).timeout(requestTimeout);
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
      ).timeout(requestTimeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteStaffMember(String memberId) async {
    final url = Uri.parse("$_cleanBase/staff/$memberId");
    try {
      final response = await http.delete(url, headers: _headers).timeout(requestTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> loginStaff({
    required String phone,
    required String pin,
  }) async {
    final url = Uri.parse("$_cleanBase/staff/login");
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "phone": phone.trim(),
          "pin": pin.trim(),
        }),
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final err = jsonDecode(response.body);
        return {
          "success": false,
          "message": err["message"] ?? "Staff login failed with code ${response.statusCode}",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Connection error: ${e.toString()}",
      };
    }
  }


  Future<Map<String, dynamic>> createPayment({
    required String orderId,
    required double amount,
    String? description,
    String? merchantId,
    String? shopName,
    String? ownerName,
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
          "merchant_id": merchantId,
          "shop_name": shopName,
          "owner_name": ownerName,
        }),
      ).timeout(requestTimeout);

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

  Future<Map<String, dynamic>> checkPaymentStatus(String paymentId) async {
    final url = Uri.parse("$_cleanBase/merchant/payment/$paymentId/status");
    try {
      final response = await http.get(
        url,
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

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

  Future<Map<String, dynamic>> getMerchantProfile() async {
    final url = Uri.parse("$_cleanBase/merchant/profile");
    try {
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["merchant"] != null) {
          return data["merchant"];
        }
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> updateMerchantProfile({
    required String shopName,
    required String ownerName,
    required String mobileNumber,
    required String gstin,
    required String address,
    String? upiId,
  }) async {
    final url = Uri.parse("$_cleanBase/merchant/update-profile");
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "shop_name": shopName,
          "owner_name": ownerName,
          "mobile_number": mobileNumber,
          "gstin": gstin,
          "address": address,
          "upi_id": upiId ?? "",
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {"success": false, "message": "Failed with status ${response.statusCode}"};
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }
}
