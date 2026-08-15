class Supplier {
  final String id;
  final String name;
  final String companyName;
  final String phone;
  final String email;
  final String address;
  final String gstin;
  double pendingPayment;
  int ordersSupplied;
  final DateTime createdAt;

  Supplier({
    required this.id,
    required this.name,
    required this.companyName,
    required this.phone,
    this.email = '',
    this.address = '',
    this.gstin = '',
    this.pendingPayment = 0.0,
    this.ordersSupplied = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] ?? json['supplierId'] ?? '',
      name: json['name'] ?? '',
      companyName: json['companyName'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      gstin: json['gstin'] ?? '',
      pendingPayment: (json['pendingPayment'] ?? 0).toDouble(),
      ordersSupplied: json['ordersSupplied'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'companyName': companyName,
      'phone': phone,
      'email': email,
      'address': address,
      'gstin': gstin,
      'pendingPayment': pendingPayment,
      'ordersSupplied': ordersSupplied,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
