import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../utils/formatter.dart';
import '../utils/icon_helper.dart';
import '../utils/refresh_bus.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _db = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _minStockCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  List<Category> _categories = [];
  int? _categoryId;
  bool _loading = true;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _categories = await _db.getAllCategories();
    if (widget.product != null) {
      final p = widget.product!;
      _nameCtrl.text = p.name;
      _skuCtrl.text = p.sku;
      _categoryId = p.categoryId;
      _minStockCtrl.text = p.minStock.toString();
      _priceCtrl.text = p.price.toStringAsFixed(0);
    } else {
      _stockCtrl.text = '0';
      _minStockCtrl.text = '5';
      _priceCtrl.text = '0';
      if (_categories.isNotEmpty) _categoryId = _categories.first.id;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
      );
      return;
    }
    final now = nowIso();
    if (_isEdit) {
      final p = widget.product!.copyWith(
        name: _nameCtrl.text.trim(),
        sku: _skuCtrl.text.trim(),
        categoryId: _categoryId,
        minStock: int.tryParse(_minStockCtrl.text) ?? 0,
        price: double.tryParse(_priceCtrl.text) ?? 0,
        updatedAt: now,
      );
      await _db.updateProduct(p);
    } else {
      final p = Product(
        name: _nameCtrl.text.trim(),
        sku: _skuCtrl.text.trim(),
        categoryId: _categoryId!,
        stock: int.tryParse(_stockCtrl.text) ?? 0,
        minStock: int.tryParse(_minStockCtrl.text) ?? 0,
        price: double.tryParse(_priceCtrl.text) ?? 0,
        createdAt: now,
        updatedAt: now,
      );
      await _db.insertProduct(p);
    }
    refreshBus.notify();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Produk' : 'Tambah Produk'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: const Text('Simpan'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Produk *',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _skuCtrl,
                    decoration: const InputDecoration(
                      labelText: 'SKU / Kode *',
                      border: OutlineInputBorder(),
                      helperText: 'Kode unik produk, mis. PRD-001',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'SKU wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Kategori *',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories
                        .map(
                          (c) => DropdownMenuItem<int>(
                            value: c.id,
                            child: Row(
                              children: [
                                Icon(
                                  iconFromCodePoint(c.icon),
                                  color: Color(c.color),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(c.name),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _categoryId = v),
                    validator: (v) => v == null ? 'Pilih kategori' : null,
                  ),
                  const SizedBox(height: 16),
                  if (!_isEdit)
                    TextFormField(
                      controller: _stockCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Stok Awal',
                        border: OutlineInputBorder(),
                        suffixText: 'unit',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  if (_isEdit)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Stok diubah lewat transaksi masuk/keluar di halaman detail.',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _minStockCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Min. Stok',
                            border: OutlineInputBorder(),
                            suffixText: 'unit',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _priceCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Harga',
                            border: OutlineInputBorder(),
                            prefixText: 'Rp ',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _save,
                    child: Text(_isEdit ? 'Perbarui Produk' : 'Simpan Produk'),
                  ),
                ],
              ),
            ),
    );
  }
}
