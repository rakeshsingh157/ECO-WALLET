import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [
    Product(id: '1', name: 'Chai Pack 250g', price: 120.0, category: 'Beverages', unit: 'pack', stock: 45, icon: 'coffee'),
    Product(id: '2', name: 'Biscuits XL', price: 80.0, category: 'Snacks', unit: 'pack', stock: 30, icon: 'cookie'),
    Product(id: '3', name: 'Mineral Water 1L', price: 20.0, category: 'Beverages', unit: 'bottle', stock: 100, icon: 'water'),
    Product(id: '4', name: 'Bread Loaf', price: 45.0, category: 'Bakery', unit: 'pcs', stock: 15, icon: 'bakery'),
    Product(id: '5', name: 'Basmati Rice Premium', price: 120.0, category: 'Grains', unit: 'kg', stock: 24, icon: 'grain'),
    Product(id: '6', name: 'Turmeric Powder 100g', price: 40.0, category: 'Spices', unit: 'pack', stock: 2, icon: 'spice'),
    Product(id: '7', name: 'Sunflower Oil 1L', price: 160.0, category: 'Oil & Ghee', unit: 'pouch', stock: 18, icon: 'oil'),
    Product(id: '8', name: 'Sugar 1kg', price: 48.0, category: 'Grains', unit: 'kg', stock: 50, icon: 'sugar'),
  ];

  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<Product> get products {
    return _products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<String> get categories => ['All', 'Beverages', 'Snacks', 'Grains', 'Spices', 'Bakery', 'Oil & Ghee'];
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setCategory(String c) {
    _selectedCategory = c;
    notifyListeners();
  }

  void addProduct(Product product) {
    _products.add(product);
    notifyListeners();
  }
}
