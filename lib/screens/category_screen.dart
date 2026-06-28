import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/category.dart';
import '../utils/icon_helper.dart';
import '../utils/refresh_bus.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _db = DatabaseHelper();
  List<Category> _categories = [];
  Map<int, int> _productCounts = {};
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
    final cats = await _db.getAllCategories();
    final products = await _db.getAllProducts();
    final counts = <int, int>{for (var c in cats) c.id!: 0};
    for (var p in products) {
      counts[p.categoryId] = (counts[p.categoryId] ?? 0) + 1;
    }
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _productCounts = counts;
      _loading = false;
    });
  }

  Future<void> _openDialog([Category? existing]) async {
    final result = await showDialog<Category>(
      context: context,
      builder: (_) => CategoryDialog(category: existing),
    );
    if (result == null) return;
    if (existing == null) {
      await _db.insertCategory(result);
    } else {
      await _db.updateCategory(result.copyWith(id: existing.id));
    }
    refreshBus.notify();
  }

  Future<void> _delete(Category c) async {
    final count = _productCounts[c.id] ?? 0;
    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tidak bisa hapus: masih ada $count produk di kategori ini.',
          ),
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Hapus kategori "${c.name}"?'),
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
      await _db.deleteCategory(c.id!);
      refreshBus.notify();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kategori')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.category_outlined,
                    size: 72,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text('Belum ada kategori'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _openDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Kategori'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final c = _categories[i];
                final count = _productCounts[c.id] ?? 0;
                return ListTile(
                  onTap: () => _openDialog(c),
                  leading: CircleAvatar(
                    backgroundColor: Color(c.color).withValues(alpha: 0.15),
                    child: Icon(
                      iconFromCodePoint(c.icon),
                      color: Color(c.color),
                    ),
                  ),
                  title: Text(
                    c.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('$count produk'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _delete(c),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CategoryDialog extends StatefulWidget {
  final Category? category;

  const CategoryDialog({super.key, this.category});

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const _colors = [
    0xFF2196F3,
    0xFF4CAF50,
    0xFFFF9800,
    0xFFE91E63,
    0xFF9C27B0,
    0xFF00BCD4,
    0xFF795548,
    0xFF607D8B,
  ];

  static const _icons = [
    Icons.devices,
    Icons.restaurant,
    Icons.edit,
    Icons.category,
    Icons.shopping_bag,
    Icons.computer,
    Icons.fastfood,
    Icons.toys,
  ];

  late int _color;
  late int _icon;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameCtrl.text = widget.category!.name;
      _color = widget.category!.color;
      _icon = widget.category!.icon;
    } else {
      _color = _colors.first;
      _icon = _icons.first.codePoint;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.category == null ? 'Tambah Kategori' : 'Edit Kategori',
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Kategori',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              const Text('Warna'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colors.map((c) {
                  final selected = c == _color;
                  return GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.black87 : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Ikon'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _icons.map((ic) {
                  final selected = ic.codePoint == _icon;
                  return GestureDetector(
                    onTap: () => setState(() => _icon = ic.codePoint),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selected
                            ? Color(_color).withValues(alpha: 0.2)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? Color(_color) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        ic,
                        color: selected ? Color(_color) : Colors.grey.shade600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              Category(
                name: _nameCtrl.text.trim(),
                color: _color,
                icon: _icon,
                createdAt:
                    widget.category?.createdAt ??
                    DateTime.now().toIso8601String(),
              ),
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
