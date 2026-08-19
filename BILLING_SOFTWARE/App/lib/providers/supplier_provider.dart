import 'package:flutter/foundation.dart';
import '../models/supplier.dart';
import '../core/api_service.dart';

class SupplierProvider with ChangeNotifier {
  List<Supplier> _suppliers = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Supplier> get suppliers {
    if (_searchQuery.isEmpty) return _suppliers;
    final q = _searchQuery.toLowerCase();
    return _suppliers.where((s) => s.name.toLowerCase().contains(q) || s.companyName.toLowerCase().contains(q) || s.phone.contains(q)).toList();
  }

  bool get isLoading => _isLoading;

  double get totalPendingPayable {
    return _suppliers.fold<double>(0.0, (sum, s) => sum + s.pendingPayment);
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  Future<bool> fetchSuppliers(ApiService apiService) async {
    _isLoading = true;
    notifyListeners();

    try {
      final remote = await apiService.getSuppliers();
      _suppliers = remote;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addSupplier(ApiService apiService, Supplier supplier) async {
    final idx = _suppliers.indexWhere((s) => s.id == supplier.id || (s.phone.isNotEmpty && s.phone == supplier.phone));
    if (idx != -1) {
      _suppliers[idx] = supplier;
    } else {
      _suppliers.insert(0, supplier);
    }
    notifyListeners();

    final success = await apiService.addSupplier(supplier);
    return success;
  }

  Future<bool> recordPaymentToSupplier(ApiService apiService, String supplierId, double amount) async {
    final idx = _suppliers.indexWhere((s) => s.id == supplierId);
    if (idx >= 0) {
      _suppliers[idx].pendingPayment = (_suppliers[idx].pendingPayment - amount) < 0 ? 0 : (_suppliers[idx].pendingPayment - amount);
      notifyListeners();
    }

    final success = await apiService.recordSupplierPayment(supplierId, amount);
    return success;
  }
}
