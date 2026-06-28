import 'package:flutter_application_1/models/category.dart';
import 'package:flutter_application_1/models/product.dart';
import 'package:flutter_application_1/models/stock_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Category model', () {
    test('toMap/fromMap round-trip preserves all fields', () {
      const c = Category(
        id: 1,
        name: 'Elektronik',
        color: 0xFF2196F3,
        icon: 12345,
        createdAt: '2026-01-01T00:00:00',
      );
      final back = Category.fromMap(c.toMap());

      expect(back.id, 1);
      expect(back.name, 'Elektronik');
      expect(back.color, 0xFF2196F3);
      expect(back.icon, 12345);
      expect(back.createdAt, '2026-01-01T00:00:00');
    });

    test('copyWith overrides only given fields', () {
      const c = Category(
        id: 1,
        name: 'ATK',
        color: 0xFFFF9800,
        icon: 99,
        createdAt: '2026-01-01T00:00:00',
      );
      final updated = c.copyWith(name: 'Alat Tulis');

      expect(updated.name, 'Alat Tulis');
      expect(updated.color, 0xFFFF9800);
      expect(updated.id, 1);
    });
  });

  group('Product model', () {
    test('toMap/fromMap round-trip preserves all fields', () {
      const p = Product(
        id: 2,
        name: 'Kopi Sachet',
        sku: 'PRD-001',
        categoryId: 1,
        stock: 10,
        minStock: 3,
        price: 15000,
        createdAt: '2026-01-01T00:00:00',
        updatedAt: '2026-01-02T00:00:00',
      );
      final back = Product.fromMap(p.toMap());

      expect(back.id, 2);
      expect(back.name, 'Kopi Sachet');
      expect(back.sku, 'PRD-001');
      expect(back.categoryId, 1);
      expect(back.stock, 10);
      expect(back.minStock, 3);
      expect(back.price, 15000);
      expect(back.createdAt, '2026-01-01T00:00:00');
    });

    test('price is parsed from int or double map value', () {
      final fromInt = Product.fromMap({
        'id': 1,
        'name': 'A',
        'sku': 'S',
        'category_id': 1,
        'stock': 0,
        'min_stock': 0,
        'price': 20000,
        'created_at': '',
        'updated_at': '',
      });
      final fromDouble = Product.fromMap({
        'id': 1,
        'name': 'A',
        'sku': 'S',
        'category_id': 1,
        'stock': 0,
        'min_stock': 0,
        'price': 20000.0,
        'created_at': '',
        'updated_at': '',
      });

      expect(fromInt.price, 20000);
      expect(fromDouble.price, 20000);
    });
  });

  group('StockTransaction model', () {
    test('IN type serializes to "IN" and back', () {
      const t = StockTransaction(
        id: 1,
        productId: 2,
        type: TransactionType.in_,
        quantity: 5,
        note: 'restock',
        date: '2026-01-01T00:00:00',
      );
      expect(t.toMap()['type'], 'IN');

      final back = StockTransaction.fromMap(t.toMap());
      expect(back.type, TransactionType.in_);
      expect(back.quantity, 5);
      expect(back.note, 'restock');
    });

    test('OUT type serializes to "OUT" and back', () {
      const t = StockTransaction(
        productId: 2,
        type: TransactionType.out,
        quantity: 2,
        note: '',
        date: '2026-01-01T00:00:00',
      );
      expect(t.toMap()['type'], 'OUT');

      final back = StockTransaction.fromMap(t.toMap());
      expect(back.type, TransactionType.out);
      expect(back.quantity, 2);
    });
  });
}
