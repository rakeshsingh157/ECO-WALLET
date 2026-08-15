import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../core/api_service.dart';

class CustomerProvider with ChangeNotifier {
  List<Customer> _customers = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Customer> get customers {
    if (_searchQuery.isEmpty) return _customers;
    final q = _searchQuery.toLowerCase();
    return _customers.where((c) => c.name.toLowerCase().contains(q) || c.phone.contains(q)).toList();
  }

  bool get isLoading => _isLoading;

  double get totalOutstandingDues {
    return _customers.fold<double>(0.0, (sum, c) => sum + c.dueAmount);
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  Future<void> fetchCustomers(ApiService apiService) async {
    _isLoading = true;
    notifyListeners();

    final remote = await apiService.getCustomers();
    if (remote.isNotEmpty) {
      _customers = remote;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addCustomer(ApiService apiService, Customer customer) async {
    _customers.insert(0, customer);
    notifyListeners();

    final success = await apiService.addCustomer(customer);
    return success;
  }

  Future<bool> recordPayment(ApiService apiService, String customerId, double amount) async {
    final idx = _customers.indexWhere((c) => c.id == customerId);
    if (idx >= 0) {
      _customers[idx].dueAmount = (_customers[idx].dueAmount - amount) < 0 ? 0 : (_customers[idx].dueAmount - amount);
      notifyListeners();
    }

    final success = await apiService.recordCustomerPayment(customerId, amount);
    return success;
  }

  Future<bool> addCredit(ApiService apiService, String customerId, double amount) async {
    final idx = _customers.indexWhere((c) => c.id == customerId);
    if (idx >= 0) {
      _customers[idx].dueAmount += amount;
      _customers[idx].totalSpent += amount;
      _customers[idx].totalOrders += 1;
      notifyListeners();
    }

    final success = await apiService.addCustomerCredit(customerId, amount);
    return success;
  }
}
