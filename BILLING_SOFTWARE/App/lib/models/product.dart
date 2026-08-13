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
    return Product(
      id: json['id'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      category: json['category'],
      unit: json['unit'] ?? 'pcs',
      stock: json['stock'] ?? 0,
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
