import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  final List<Product> _products = [];

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
