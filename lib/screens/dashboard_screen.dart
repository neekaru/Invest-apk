import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../utils/formatter.dart';
import '../utils/refresh_bus.dart';
import '../widgets/empty_state.dart';
import '../widgets/stat_card.dart';
import '../widgets/product_tile.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onViewAllProducts;

  const DashboardScreen({super.key, this.onViewAllProducts});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _db = DatabaseHelper();
  int _totalProducts = 0;
  double _totalValue = 0;
  int _lowStockCount = 0;
  List<Product> _lowStockProducts = [];
  Map<int, Category> _categoryMap = {};
  bool _loading = true;

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
    final total = await _db.getTotalProducts();
    final value = await _db.getTotalStockValue();
    final lowCount = await _db.getLowStockCount();
    final lowProducts = await _db.getLowStockProducts();
    final cats = await _db.getAllCategories();
    if (!mounted) return;
    setState(() {
      _totalProducts = total;
      _totalValue = value;
      _lowStockCount = lowCount;
      _lowStockProducts = lowProducts;
      _categoryMap = {for (var c in cats) c.id!: c};
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventaris')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.inventory_2,
                          label: 'Total Produk',
                          value: '$_totalProducts',
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.warning_amber_rounded,
                          label: 'Stok Menipis',
                          value: '$_lowStockCount',
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StatCard(
                    icon: Icons.attach_money,
                    label: 'Nilai Total Stok',
                    value: formatRupiah(_totalValue),
                    color: Colors.green,
                  ),
                  const SizedBox(height: 24),
                  _lowStockSection(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
          );
          if (changed == true) refreshBus.notify();
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
    );
  }

  Widget _lowStockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Stok Menipis',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (widget.onViewAllProducts != null)
              TextButton(
                onPressed: widget.onViewAllProducts,
                child: const Text('Lihat semua'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_lowStockProducts.isEmpty)
          const EmptyState(
            icon: Icons.check_circle_outline,
            title: 'Stok Aman',
            message: 'Tidak ada produk dengan stok menipis.',
          )
        else
          Card(
            child: Column(
              children: _lowStockProducts.map(_buildLowStockTile).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildLowStockTile(Product p) {
    final cat = _categoryMap[p.categoryId];
    return ProductTile(
      product: p,
      categoryName: cat?.name ?? '-',
      categoryColor: cat?.color ?? 0xFF9E9E9E,
      categoryIcon: cat?.icon ?? Icons.category.codePoint,
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
        );
        refreshBus.notify();
      },
    );
  }
}
