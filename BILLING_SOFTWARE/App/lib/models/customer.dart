class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String aadhaarNumber;
  double dueAmount;
  double totalSpent;
  int totalOrders;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.address = '',
    this.aadhaarNumber = '',
    this.dueAmount = 0.0,
    this.totalSpent = 0.0,
    this.totalOrders = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString() ?? json['customer_id']?.toString() ?? json['customerId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      aadhaarNumber: json['aadhaar_number']?.toString() ?? json['aadhaarNumber']?.toString() ?? '',
      dueAmount: (json['due_amount'] as num?)?.toDouble() ?? (json['dueAmount'] as num?)?.toDouble() ?? 0.0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? (json['totalOrders'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'aadhaarNumber': aadhaarNumber,
      'dueAmount': dueAmount,
      'totalSpent': totalSpent,
      'totalOrders': totalOrders,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
