import 'package:flutter/material.dart';
import '../models/product.dart';
import '../core/api_service.dart';

class ProductProvider extends ChangeNotifier {
  final List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<Product> get products {
    return _products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.barcode != null && p.barcode!.toLowerCase().contains(_searchQuery.toLowerCase()));
      final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<Product> get allProducts => _products;
  List<Product> get lowStockProducts => _products.where((p) => p.isLowStock).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<String> get categories => ['All', 'Groceries', 'Beverages', 'Snacks', 'Grains', 'Spices', 'Bakery', 'Oil & Ghee', 'Dairy', 'Personal Care', 'General'];
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  Product? findProductByBarcode(String code) {
    final clean = code.trim().toLowerCase();
    final cleanDigits = clean.replaceAll(RegExp(r'\D'), '');

    for (final p in _products) {
      if (p.barcode != null && p.barcode!.trim().isNotEmpty) {
        final pBarcodeClean = p.barcode!.trim().toLowerCase();
        final pBarcodeDigits = pBarcodeClean.replaceAll(RegExp(r'\D'), '');

        if (pBarcodeClean == clean) return p;
        if (cleanDigits.isNotEmpty && pBarcodeDigits.isNotEmpty) {
          if (cleanDigits == pBarcodeDigits) return p;
          final s1 = cleanDigits.replaceFirst(RegExp(r'^0+'), '');
          final s2 = pBarcodeDigits.replaceFirst(RegExp(r'^0+'), '');
          if (s1.isNotEmpty && s1 == s2) return p;
          if (cleanDigits.length >= 8 && pBarcodeDigits.length >= 8) {
            if (cleanDigits.contains(pBarcodeDigits) || pBarcodeDigits.contains(cleanDigits)) return p;
          }
        }
      }
      if (p.id.trim().toLowerCase() == clean) {
        return p;
      }
      if (p.name.trim().toLowerCase() == clean) {
        return p;
      }
    }
    return null;
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setCategory(String c) {
    _selectedCategory = c;
    notifyListeners();
  }

  Future<bool> fetchProducts(String baseUrl, String apiKey) async {
    if (baseUrl.isEmpty) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final apiService = ApiService(baseUrl: baseUrl, apiKey: apiKey);
      final remoteProducts = await apiService.getProducts();
      _products.clear();
      _products.addAll(remoteProducts);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createProduct(String baseUrl, String apiKey, Product product) async {
    final existingIdx = _products.indexWhere((p) => p.id == product.id || (p.name.trim().toLowerCase() == product.name.trim().toLowerCase() && p.category == product.category && p.unit == product.unit));
    if (existingIdx != -1) {
      _products[existingIdx] = product;
    } else {
      _products.insert(0, product);
    }
    notifyListeners();

    try {
      final apiService = ApiService(baseUrl: baseUrl, apiKey: apiKey);
      final success = await apiService.addProduct(product);
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> updateProduct(String baseUrl, String apiKey, Product updatedProduct) async {
    final idx = _products.indexWhere((p) => p.id == updatedProduct.id);
    if (idx != -1) {
      _products[idx] = updatedProduct;
      notifyListeners();
    }

    try {
      final apiService = ApiService(baseUrl: baseUrl, apiKey: apiKey);
      return await apiService.addProduct(updatedProduct);
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> removeProduct(String baseUrl, String apiKey, String productId) async {
    _products.removeWhere((p) => p.id == productId);
    notifyListeners();

    try {
      final apiService = ApiService(baseUrl: baseUrl, apiKey: apiKey);
      return await apiService.deleteProduct(productId);
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  void addProduct(Product product) {
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      _products[idx] = product;
    } else {
      _products.insert(0, product);
    }
    notifyListeners();
  }

  void deductStock(List<dynamic> items) {
    for (final item in items) {
      final pid = item.product.id;
      final qty = (item.quantity as num).toDouble();
      final idx = _products.indexWhere((p) => p.id == pid);
      if (idx != -1) {
        final currentStock = _products[idx].stock;
        final newStock = currentStock - qty;
        _products[idx] = _products[idx].copyWith(stock: newStock < 0.0 ? 0.0 : newStock);
      }
    }
    notifyListeners();
  }

  void restoreStock(String productId, double quantity) {
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      final currentStock = _products[idx].stock;
      _products[idx] = _products[idx].copyWith(stock: currentStock + quantity);
      notifyListeners();
    }
  }
}
