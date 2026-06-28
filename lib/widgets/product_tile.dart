import 'package:flutter/material.dart';

import '../models/product.dart';
import '../utils/formatter.dart';
import '../utils/icon_helper.dart';

class ProductTile extends StatelessWidget {
  final Product product;
  final String categoryName;
  final int categoryColor;
  final int categoryIcon;
  final VoidCallback onTap;

  const ProductTile({
    super.key,
    required this.product,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
    required this.onTap,
  });

  Color get _stockColor {
    if (product.stock <= 0) return Colors.red;
    if (product.stock <= product.minStock) return Colors.orange;
    return Colors.green;
  }

  String get _stockLabel {
    if (product.stock <= 0) return 'Habis';
    if (product.stock <= product.minStock) return 'Menipis';
    return 'Tersedia';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Color(categoryColor).withValues(alpha: 0.15),
        child: Icon(
          iconFromCodePoint(categoryIcon),
          color: Color(categoryColor),
        ),
      ),
      title: Text(
        product.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('${product.sku} • $categoryName'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatRupiah(product.price),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2, size: 14, color: _stockColor),
              const SizedBox(width: 4),
              Text(
                '${product.stock} • $_stockLabel',
                style: TextStyle(color: _stockColor, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
