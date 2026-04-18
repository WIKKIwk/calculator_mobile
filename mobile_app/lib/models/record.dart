import 'user.dart';
import 'product.dart';

class Record {
  final String id;
  final User user;
  final Product product;
  final double quantity;
  final String createdAt;

  /// Internet yo'qda saqlangan, serverga hali yuborilmagan qator.
  final bool isLocalPending;

  const Record({
    required this.id,
    required this.user,
    required this.product,
    required this.quantity,
    required this.createdAt,
    this.isLocalPending = false,
  });

  factory Record.fromJson(Map<String, dynamic> json) {
    return Record(
      id: json['id'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num).toDouble(),
      createdAt: json['createdAt'] as String,
    );
  }
}
