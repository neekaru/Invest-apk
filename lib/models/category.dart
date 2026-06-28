class Category {
  final int? id;
  final String name;
  final int color;
  final int icon;
  final String createdAt;

  const Category({
    this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'color': color,
    'icon': icon,
    'created_at': createdAt,
  };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'] as int?,
    name: map['name'] as String,
    color: map['color'] as int,
    icon: map['icon'] as int,
    createdAt: map['created_at'] as String,
  );

  Category copyWith({
    int? id,
    String? name,
    int? color,
    int? icon,
    String? createdAt,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color ?? this.color,
    icon: icon ?? this.icon,
    createdAt: createdAt ?? this.createdAt,
  );
}
