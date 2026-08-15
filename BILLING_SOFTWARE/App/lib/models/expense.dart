class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final String paymentMode;
  final String notes;
  final DateTime date;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    this.paymentMode = 'Cash',
    this.notes = '',
    DateTime? date,
  }) : date = date ?? DateTime.now();

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      category: json['category'] ?? 'General',
      paymentMode: json['paymentMode'] ?? 'Cash',
      notes: json['notes'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'paymentMode': paymentMode,
      'notes': notes,
      'date': date.toIso8601String(),
    };
  }
}
