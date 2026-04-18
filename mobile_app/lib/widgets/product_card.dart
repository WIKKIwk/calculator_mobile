import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import 'edit_product_sheet.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final int index;
  final VoidCallback onProductUpdated;

  const ProductCard({
    super.key,
    required this.product,
    required this.index,
    required this.onProductUpdated,
  });

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProductSheet(
        product: product,
        onProductUpdated: onProductUpdated,
      ),
    );
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###', 'uz_UZ');
    return '${formatter.format(price)} so\'m';
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd.MM.yyyy • HH:mm').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedSlide(
      offset: Offset.zero,
      duration: Duration(milliseconds: 300 + index * 50),
      child: ListTile(
        onTap: () => _openEditSheet(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: Text(
            '${index + 1}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatDate(product.createdAt),
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        trailing: Text(
          _formatPrice(product.price),
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
