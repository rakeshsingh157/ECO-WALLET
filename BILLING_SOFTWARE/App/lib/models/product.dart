class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final String unit;
  final int stock;
  final String icon;
  final String? barcode;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.unit,
    required this.stock,
    this.icon = 'box',
    this.barcode,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawStock = json['stock'] ?? 0;
    final parsedStock = (rawStock is num) ? rawStock.toInt() : (int.tryParse(rawStock.toString()) ?? 0);
    return Product(
      id: json['id'] ?? json['product_id'] ?? '',
      name: json['name'] ?? 'Product',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? 'General',
      unit: json['unit'] ?? 'pcs',
      stock: parsedStock < 0 ? 0 : parsedStock,
      icon: json['icon'] ?? 'box',
      barcode: json['barcode'] ?? json['sku'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category': category,
      'unit': unit,
      'stock': stock,
      'icon': icon,
      'barcode': barcode,
    };
  }
}
