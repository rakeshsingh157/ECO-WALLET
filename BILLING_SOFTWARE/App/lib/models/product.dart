class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final String unit;
  final int stock;
  final int lowStockAlert;
  final String icon;
  final String? barcode;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.unit,
    required this.stock,
    this.lowStockAlert = 5,
    this.icon = 'box',
    this.barcode,
  });

  bool get isLowStock => stock <= lowStockAlert;
  bool get isOutOfStock => stock <= 0;

  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? category,
    String? unit,
    int? stock,
    int? lowStockAlert,
    String? icon,
    String? barcode,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      stock: stock ?? this.stock,
      lowStockAlert: lowStockAlert ?? this.lowStockAlert,
      icon: icon ?? this.icon,
      barcode: barcode ?? this.barcode,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawStock = json['stock'] ?? 0;
    final parsedStock = (rawStock is num) ? rawStock.toInt() : (int.tryParse(rawStock.toString()) ?? 0);
    final rawAlert = json['min_stock_alert'] ?? json['low_stock_alert'] ?? 5;
    final parsedAlert = (rawAlert is num) ? rawAlert.toInt() : (int.tryParse(rawAlert.toString()) ?? 5);

    return Product(
      id: json['id'] ?? json['product_id'] ?? '',
      name: json['name'] ?? 'Product',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? 'General',
      unit: json['unit'] ?? 'pcs',
      stock: parsedStock < 0 ? 0 : parsedStock,
      lowStockAlert: parsedAlert < 0 ? 0 : parsedAlert,
      icon: json['icon'] ?? 'box',
      barcode: json['barcode'] ?? json['sku'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': id,
      'name': name,
      'price': price,
      'category': category,
      'unit': unit,
      'stock': stock < 0 ? 0 : stock,
      'min_stock_alert': lowStockAlert < 0 ? 0 : lowStockAlert,
      'low_stock_alert': lowStockAlert < 0 ? 0 : lowStockAlert,
      'icon': icon,
      'barcode': barcode,
    };
  }
}
