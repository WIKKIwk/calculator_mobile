import 'user.dart';
import 'product.dart';

/// Hive / JSON dan kelgan `Map<dynamic, dynamic>` uchun.
Map<String, dynamic> _jsonMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return Map<String, dynamic>.from(
      value.map((k, v) => MapEntry(k.toString(), v)),
    );
  }
  throw ArgumentError('JSON map kutilgan edi: $value');
}

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
      user: User.fromJson(_jsonMap(json['user'])),
      product: Product.fromJson(_jsonMap(json['product'])),
      quantity: (json['quantity'] as num).toDouble(),
      createdAt: json['createdAt'] as String,
    );
  }
}
