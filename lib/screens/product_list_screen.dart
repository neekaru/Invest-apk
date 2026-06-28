import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../utils/refresh_bus.dart';
import '../widgets/empty_state.dart';
import '../widgets/product_tile.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _db = DatabaseHelper();
  List<Product> _allProducts = [];
  List<Product> _filtered = [];
  List<Category> _categories = [];
  Map<int, Category> _categoryMap = {};
  bool _loading = true;
  String _search = '';
  int? _filterCategoryId;

  @override
  void initState() {
    super.initState();
    _loadData();
    refreshBus.addListener(_loadData);
  }

  @override
  void dispose() {
    refreshBus.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    final cats = await _db.getAllCategories();
    final products = await _db.getAllProducts();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _categoryMap = {for (var c in cats) c.id!: c};
      _allProducts = products;
      _loading = false;
    });
    _applyFilter();
  }

  void _applyFilter() {
    final q = _search.toLowerCase();
    setState(() {
      _filtered = _allProducts.where((p) {
        final matchSearch =
            q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q);
        final matchCat =
            _filterCategoryId == null || p.categoryId == _filterCategoryId;
        return matchSearch && matchCat;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produk')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Cari nama / SKU...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      _search = v;
                      _applyFilter();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<int?>(
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      labelText: 'Kategori',
                    ),
                    initialValue: _filterCategoryId,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Semua'),
                      ),
                      ..._categories.map(
                        (c) => DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      _filterCategoryId = v;
                      _applyFilter();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                ? EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Belum ada produk',
                    message: 'Tambahkan produk pertama Anda.',
                    actionLabel: 'Tambah Produk',
                    onAction: () async {
                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductFormScreen(),
                        ),
                      );
                      if (changed == true) refreshBus.notify();
                    },
                  )
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = _filtered[i];
                      final cat = _categoryMap[p.categoryId];
                      return ProductTile(
                        product: p,
                        categoryName: cat?.name ?? '-',
                        categoryColor: cat?.color ?? 0xFF9E9E9E,
                        categoryIcon: cat?.icon ?? Icons.category.codePoint,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(product: p),
                            ),
                          );
                          refreshBus.notify();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
          );
          if (changed == true) refreshBus.notify();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
