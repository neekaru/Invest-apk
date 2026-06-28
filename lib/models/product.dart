class Product {
  final int? id;
  final String name;
  final String sku;
  final int categoryId;
  final int stock;
  final int minStock;
  final double price;
  final String createdAt;
  final String updatedAt;

  const Product({
    this.id,
    required this.name,
    required this.sku,
    required this.categoryId,
    required this.stock,
    required this.minStock,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'sku': sku,
    'category_id': categoryId,
    'stock': stock,
    'min_stock': minStock,
    'price': price,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
    id: map['id'] as int?,
    name: map['name'] as String,
    sku: map['sku'] as String,
    categoryId: map['category_id'] as int,
    stock: map['stock'] as int,
    minStock: map['min_stock'] as int,
    price: (map['price'] as num).toDouble(),
    createdAt: map['created_at'] as String,
    updatedAt: map['updated_at'] as String,
  );

  Product copyWith({
    int? id,
    String? name,
    String? sku,
    int? categoryId,
    int? stock,
    int? minStock,
    double? price,
    String? createdAt,
    String? updatedAt,
  }) => Product(
    id: id ?? this.id,
    name: name ?? this.name,
    sku: sku ?? this.sku,
    categoryId: categoryId ?? this.categoryId,
    stock: stock ?? this.stock,
    minStock: minStock ?? this.minStock,
    price: price ?? this.price,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
