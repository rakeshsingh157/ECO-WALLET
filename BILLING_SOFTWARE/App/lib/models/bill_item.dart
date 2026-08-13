import 'product.dart';

class BillItem {
  final Product product;
  int quantity;

  BillItem({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;
}
