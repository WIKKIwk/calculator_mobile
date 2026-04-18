class User {
  final String id;
  final String firstName;
  final String lastName;
  final String createdAt;

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      createdAt: json['createdAt'] as String,
    );
  }

  /// Sharif bo'sh bo'lishi mumkin.
  String get displayName {
    final f = firstName.trim();
    final l = lastName.trim();
    if (l.isEmpty) return f;
    return '$f $l';
  }
}
