enum TransactionType { in_, out }

class StockTransaction {
  final int? id;
  final int productId;
  final TransactionType type;
  final int quantity;
  final String note;
  final String date;

  const StockTransaction({
    this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.note,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'product_id': productId,
    'type': type == TransactionType.in_ ? 'IN' : 'OUT',
    'quantity': quantity,
    'note': note,
    'date': date,
  };

  factory StockTransaction.fromMap(Map<String, dynamic> map) =>
      StockTransaction(
        id: map['id'] as int?,
        productId: map['product_id'] as int,
        type: map['type'] == 'IN' ? TransactionType.in_ : TransactionType.out,
        quantity: map['quantity'] as int,
        note: map['note'] as String,
        date: map['date'] as String,
      );

  StockTransaction copyWith({
    int? id,
    int? productId,
    TransactionType? type,
    int? quantity,
    String? note,
    String? date,
  }) => StockTransaction(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    type: type ?? this.type,
    quantity: quantity ?? this.quantity,
    note: note ?? this.note,
    date: date ?? this.date,
  );
}
