import 'package:flutter/material.dart';
import '../models/product.dart';
import '../core/api_service.dart';

class ProductProvider extends ChangeNotifier {
  final List<Product> _products = [];
  bool _isLoading = false;

  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<Product> get products {
    return _products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<Product> get allProducts => _products;
  List<Product> get lowStockProducts => _products.where((p) => p.stock <= 5).toList();
  bool get isLoading => _isLoading;

  List<String> get categories => ['All', 'Beverages', 'Snacks', 'Grains', 'Spices', 'Bakery', 'Oil & Ghee', 'Dairy', 'Personal Care', 'General'];
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

  /// Fetch products live from MongoDB Atlas
  Future<void> fetchProducts(String baseUrl, String apiKey) async {
    if (baseUrl.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    try {
      final apiService = ApiService(baseUrl: baseUrl, apiKey: apiKey);
      final remoteProducts = await apiService.getProducts();
      if (remoteProducts.isNotEmpty) {
        _products.clear();
        _products.addAll(remoteProducts);
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  /// Add new product and persist directly to MongoDB Atlas
  Future<bool> createProduct(String baseUrl, String apiKey, Product product) async {
    _products.insert(0, product);
    notifyListeners();

    try {
      final apiService = ApiService(baseUrl: baseUrl, apiKey: apiKey);
      final success = await apiService.addProduct(product);
      return success;
    } catch (_) {
      return false;
    }
  }

  /// Delete product from MongoDB Atlas
  Future<bool> removeProduct(String baseUrl, String apiKey, String productId) async {
    _products.removeWhere((p) => p.id == productId);
    notifyListeners();

    try {
      final apiService = ApiService(baseUrl: baseUrl, apiKey: apiKey);
      return await apiService.deleteProduct(productId);
    } catch (_) {
      return false;
    }
  }

  void addProduct(Product product) {
    _products.add(product);
    notifyListeners();
  }
}
