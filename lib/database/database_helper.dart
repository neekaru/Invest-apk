import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../models/stock_transaction.dart';
import '../utils/formatter.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'inventory.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        icon INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sku TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        min_stock INTEGER NOT NULL DEFAULT 0,
        price REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        date TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    await _seedCategories(db);
  }

  Future<void> _seedCategories(Database db) async {
    final now = nowIso();
    final seeds = [
      Category(
        name: 'Elektronik',
        color: 0xFF2196F3,
        icon: Icons.devices.codePoint,
        createdAt: now,
      ),
      Category(
        name: 'Makanan',
        color: 0xFF4CAF50,
        icon: Icons.restaurant.codePoint,
        createdAt: now,
      ),
      Category(
        name: 'ATK',
        color: 0xFFFF9800,
        icon: Icons.edit.codePoint,
        createdAt: now,
      ),
      Category(
        name: 'Lainnya',
        color: 0xFF9E9E9E,
        icon: Icons.category.codePoint,
        createdAt: now,
      ),
    ];
    for (final c in seeds) {
      final map = c.toMap()..remove('id');
      await db.insert('categories', map);
    }
  }

  // ===== Category CRUD =====
  Future<int> insertCategory(Category category) async {
    final db = await database;
    final map = category.toMap()..remove('id');
    return await db.insert('categories', map);
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'name ASC');
    return maps.map(Category.fromMap).toList();
  }

  Future<Category?> getCategory(int id) async {
    final db = await database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  // ===== Product CRUD =====
  Future<int> insertProduct(Product product) async {
    final db = await database;
    final map = product.toMap()..remove('id');
    return await db.insert('products', map);
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    await db.delete(
      'stock_transactions',
      where: 'product_id = ?',
      whereArgs: [id],
    );
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'name ASC');
    return maps.map(Product.fromMap).toList();
  }

  Future<Product?> getProduct(int id) async {
    final db = await database;
    final maps = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'name LIKE ? OR sku LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map(Product.fromMap).toList();
  }

  Future<List<Product>> getProductsByCategory(int categoryId) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'name ASC',
    );
    return maps.map(Product.fromMap).toList();
  }

  Future<List<Product>> getLowStockProducts() async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'stock <= min_stock',
      orderBy: 'stock ASC',
    );
    return maps.map(Product.fromMap).toList();
  }

  // ===== StockTransaction CRUD =====
  Future<int> insertTransaction(StockTransaction tx) async {
    final db = await database;
    final map = tx.toMap()..remove('id');
    return await db.insert('stock_transactions', map);
  }

  Future<List<StockTransaction>> getTransactionsForProduct(
    int productId,
  ) async {
    final db = await database;
    final maps = await db.query(
      'stock_transactions',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'date DESC',
    );
    return maps.map(StockTransaction.fromMap).toList();
  }

  Future<List<StockTransaction>> getAllTransactions() async {
    final db = await database;
    final maps = await db.query('stock_transactions', orderBy: 'date DESC');
    return maps.map(StockTransaction.fromMap).toList();
  }

  // ===== Business logic: adjust stock + record transaction atomically =====
  Future<void> addStock(int productId, int quantity, String note) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE products SET stock = stock + ?, updated_at = ? WHERE id = ?',
        [quantity, nowIso(), productId],
      );
      await txn.insert('stock_transactions', {
        'product_id': productId,
        'type': 'IN',
        'quantity': quantity,
        'note': note,
        'date': nowIso(),
      });
    });
  }

  Future<void> removeStock(int productId, int quantity, String note) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE products SET stock = stock - ?, updated_at = ? WHERE id = ?',
        [quantity, nowIso(), productId],
      );
      await txn.insert('stock_transactions', {
        'product_id': productId,
        'type': 'OUT',
        'quantity': quantity,
        'note': note,
        'date': nowIso(),
      });
    });
  }

  // ===== Dashboard stats =====
  Future<int> getTotalProducts() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS count FROM products');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<double> getTotalStockValue() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(stock * price) AS total FROM products',
    );
    if (result.isEmpty || result.first['total'] == null) return 0;
    return (result.first['total'] as num).toDouble();
  }

  Future<int> getLowStockCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM products WHERE stock <= min_stock',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
