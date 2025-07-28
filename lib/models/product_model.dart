class Product {
  final String id;
  final String postId;
  final String creatorId;
  final double price;
  final bool resaleAllowed;
  final double royaltyPercent;
  final String licenseInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.postId,
    required this.creatorId,
    required this.price,
    required this.resaleAllowed,
    required this.royaltyPercent,
    required this.licenseInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['_id'] ?? '',
      postId: map['postId'] ?? '',
      creatorId: map['creatorId'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      resaleAllowed: map['resaleAllowed'] ?? false,
      royaltyPercent: (map['royaltyPercent'] ?? 0).toDouble(),
      licenseInfo: map['licenseInfo'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'postId': postId,
      'creatorId': creatorId,
      'price': price,
      'resaleAllowed': resaleAllowed,
      'royaltyPercent': royaltyPercent,
      'licenseInfo': licenseInfo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
} 