import 'product.dart';

class BillItem {
  final Product product;
  double quantity;
  double returnedQuantity;

  BillItem({
    required this.product,
    this.quantity = 1.0,
    this.returnedQuantity = 0.0,
  });

  double get totalPrice => product.price * quantity;
  double get remainingQuantity => (quantity - returnedQuantity).clamp(0.0, quantity);
  bool get isFullyReturned => returnedQuantity >= quantity && quantity > 0;
  bool get isPartiallyReturned => returnedQuantity > 0 && returnedQuantity < quantity;

  String get formattedQuantity {
    final u = product.unit.toLowerCase().trim();
    if (u == 'kg') {
      if (quantity < 1.0) {
        final grams = (quantity * 1000).round();
        return '$grams g';
      }
      final isWhole = quantity.truncateToDouble() == quantity;
      return '${quantity.toStringAsFixed(isWhole ? 0 : (quantity * 1000 % 1 == 0 ? 3 : 2))} kg';
    } else if (u == 'ltr' || u == 'l' || u == 'liter') {
      if (quantity < 1.0) {
        final ml = (quantity * 1000).round();
        return '$ml ml';
      }
      final isWhole = quantity.truncateToDouble() == quantity;
      return '${quantity.toStringAsFixed(isWhole ? 0 : 2)} L';
    } else if (u == 'g' || u == 'gm' || u == 'gram') {
      final isWhole = quantity.truncateToDouble() == quantity;
      return '${quantity.toStringAsFixed(isWhole ? 0 : 1)} g';
    } else if (u == 'ml') {
      final isWhole = quantity.truncateToDouble() == quantity;
      return '${quantity.toStringAsFixed(isWhole ? 0 : 1)} ml';
    } else {
      final isWhole = quantity.truncateToDouble() == quantity;
      return '${quantity.toStringAsFixed(isWhole ? 0 : 1)} ${product.unit}';
    }
  }

  String formatQuantityValue(double qty) {
    final u = product.unit.toLowerCase().trim();
    if (u == 'kg') {
      if (qty < 1.0) {
        final grams = (qty * 1000).round();
        return '$grams g';
      }
      final isWhole = qty.truncateToDouble() == qty;
      return '${qty.toStringAsFixed(isWhole ? 0 : (qty * 1000 % 1 == 0 ? 3 : 2))} kg';
    } else if (u == 'ltr' || u == 'l' || u == 'liter') {
      if (qty < 1.0) {
        final ml = (qty * 1000).round();
        return '$ml ml';
      }
      final isWhole = qty.truncateToDouble() == qty;
      return '${qty.toStringAsFixed(isWhole ? 0 : 2)} L';
    } else if (u == 'g' || u == 'gm' || u == 'gram') {
      final isWhole = qty.truncateToDouble() == qty;
      return '${qty.toStringAsFixed(isWhole ? 0 : 1)} g';
    } else if (u == 'ml') {
      final isWhole = qty.truncateToDouble() == qty;
      return '${qty.toStringAsFixed(isWhole ? 0 : 1)} ml';
    } else {
      final isWhole = qty.truncateToDouble() == qty;
      return '${qty.toStringAsFixed(isWhole ? 0 : 1)} ${product.unit}';
    }
  }
}
