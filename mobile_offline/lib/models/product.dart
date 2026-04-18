class Product {
  final String id;
  final String name;
  final double price;
  final String createdAt;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      createdAt: json['createdAt'] as String,
    );
  }
}
