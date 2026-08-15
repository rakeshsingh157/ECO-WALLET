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
      id: json['id'] ?? json['customerId'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      aadhaarNumber: json['aadhaarNumber'] ?? '',
      dueAmount: (json['dueAmount'] ?? 0).toDouble(),
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      totalOrders: json['totalOrders'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
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
