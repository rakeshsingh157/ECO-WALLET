class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final String unit; // kg, pack, pcs, L
  final int stock;
  final String icon;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.unit,
    required this.stock,
    required this.icon,
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
    };
  }
}
