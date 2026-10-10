import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';

/// Pill badge indicating product availability.
class StockBadge extends StatelessWidget {
  final Product product;

  const StockBadge({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    if (product.isOutOfStock) {
      return _buildPill(
        label: 'Out of Stock',
        bgColor: const Color(0xFFFEE2E2),
        textColor: const Color(0xFF991B1B),
      );
    }

    if (product.isLowStock) {
      return _buildPill(
        label: 'Only ${product.stockQuantity} left',
        bgColor: const Color(0xFFFEF3C7),
        textColor: const Color(0xFF92400E),
      );
    }

    return _buildPill(
      label: 'In Stock',
      bgColor: const Color(0xFFDCFCE7),
      textColor: const Color(0xFF166534),
    );
  }

  Widget _buildPill({
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: textColor,
        ),
      ),
    );
  }
}
