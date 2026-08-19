import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../core/api_service.dart';

class ExpenseProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  bool _isLoading = false;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;

  double get todayExpenseTotal {
    final now = DateTime.now();
    return _expenses.where((e) => e.date.year == now.year && e.date.month == now.month && e.date.day == now.day).fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  double get totalExpenses {
    return _expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  Future<bool> fetchExpenses(ApiService apiService, {String? period, String? category}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final remote = await apiService.getExpenses(period: period, category: category);
      _expenses = remote;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addExpense(ApiService apiService, Expense expense) async {
    _expenses.insert(0, expense);
    notifyListeners();

    final success = await apiService.addExpense(expense);
    return success;
  }

  Future<bool> updateExpense(ApiService apiService, Expense expense) async {
    final idx = _expenses.indexWhere((e) => e.id == expense.id);
    if (idx >= 0) {
      _expenses[idx] = expense;
      notifyListeners();
    }

    final success = await apiService.updateExpense(expense);
    return success;
  }

  Future<bool> removeExpense(ApiService apiService, String id) async {
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();

    final success = await apiService.deleteExpense(id);
    return success;
  }
}
