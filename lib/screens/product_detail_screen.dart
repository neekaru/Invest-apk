import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/stock_transaction.dart';
import '../utils/formatter.dart';
import '../utils/icon_helper.dart';
import '../utils/refresh_bus.dart';
import 'product_form_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _db = DatabaseHelper();
  late Product _product;
  Category? _category;
  List<StockTransaction> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _loadData();
  }

  Future<void> _loadData() async {
    final p = await _db.getProduct(widget.product.id!);
    final cat = await _db.getCategory(widget.product.categoryId);
    final txs = await _db.getTransactionsForProduct(widget.product.id!);
    if (!mounted) return;
    setState(() {
      if (p != null) _product = p;
      _category = cat;
      _transactions = txs;
      _loading = false;
    });
  }

  Color get _stockColor {
    if (_product.stock <= 0) return Colors.red;
    if (_product.stock <= _product.minStock) return Colors.orange;
    return Colors.green;
  }

  String get _stockLabel {
    if (_product.stock <= 0) return 'Habis';
    if (_product.stock <= _product.minStock) return 'Menipis';
    return 'Tersedia';
  }

  Future<void> _showStockDialog(bool isAdd) async {
    final qtyCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAdd ? 'Tambah Stok' : 'Kurangi Stok'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: qtyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Jumlah',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Jumlah harus lebih dari 0';
                  if (!isAdd && n > _product.stock) {
                    return 'Melebihi stok saat ini (${_product.stock})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result == true) {
      final qty = int.parse(qtyCtrl.text);
      final note = noteCtrl.text.trim();
      if (isAdd) {
        await _db.addStock(_product.id!, qty, note);
      } else {
        await _db.removeStock(_product.id!, qty, note);
      }
      refreshBus.notify();
      await _loadData();
    }
  }

  Future<void> _edit() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: _product)),
    );
    if (changed == true) {
      refreshBus.notify();
      await _loadData();
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text(
          'Hapus "${_product.name}"? Riwayat transaksi juga akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _db.deleteProduct(_product.id!);
      if (mounted) {
        refreshBus.notify();
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_product.name),
        actions: [
          IconButton(onPressed: _edit, icon: const Icon(Icons.edit_outlined)),
          IconButton(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _headerCard(),
                const SizedBox(height: 12),
                _infoCard(),
                const SizedBox(height: 12),
                _stockActions(),
                const SizedBox(height: 24),
                _transactionHistory(),
              ],
            ),
    );
  }

  Widget _headerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Color(
                _category?.color ?? 0xFF9E9E9E,
              ).withValues(alpha: 0.15),
              child: Icon(
                iconFromCodePoint(_category?.icon ?? Icons.category.codePoint),
                color: Color(_category?.color ?? 0xFF9E9E9E),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _product.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('SKU: ${_product.sku}'),
                  Text('Kategori: ${_category?.name ?? '-'}'),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _stockColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _stockLabel,
                style: TextStyle(
                  color: _stockColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard() {
    final items = [
      ('Harga Satuan', formatRupiah(_product.price), Icons.payments),
      ('Stok Saat Ini', '${_product.stock} unit', Icons.inventory),
      ('Min. Stok', '${_product.minStock} unit', Icons.warning_amber),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: items
              .map(
                (e) => Expanded(
                  child: Column(
                    children: [
                      Icon(e.$3, color: Colors.indigo),
                      const SizedBox(height: 8),
                      Text(
                        e.$2,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.$1,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _stockActions() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _showStockDialog(true),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Stok'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: _product.stock <= 0
                ? null
                : () => _showStockDialog(false),
            icon: const Icon(Icons.remove),
            label: const Text('Kurangi Stok'),
          ),
        ),
      ],
    );
  }

  Widget _transactionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Riwayat Transaksi',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_transactions.isEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.history, color: Colors.grey),
              title: const Text('Belum ada transaksi'),
            ),
          )
        else
          Card(
            child: Column(children: _transactions.map(_buildTxTile).toList()),
          ),
      ],
    );
  }

  Widget _buildTxTile(StockTransaction tx) {
    final isIn = tx.type == TransactionType.in_;
    final color = isIn ? Colors.green : Colors.red;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(isIn ? Icons.south_west : Icons.north_east, color: color),
      ),
      title: Text(
        '${isIn ? '+' : '-'}${tx.quantity} unit',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${formatDateTime(tx.date)}${tx.note.isNotEmpty ? ' • ${tx.note}' : ''}',
      ),
      trailing: Text(isIn ? 'Masuk' : 'Keluar', style: TextStyle(color: color)),
    );
  }
}
