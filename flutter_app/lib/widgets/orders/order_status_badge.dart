import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../theme/app_theme.dart';

/// Pill badge displaying order lifecycle state with semantic color coding.
class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status) {
      case OrderStatus.pending:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        break;
      case OrderStatus.confirmed:
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1E40AF);
        break;
      case OrderStatus.processing:
        bg = const Color(0xFFF3E8FF);
        fg = const Color(0xFF6B21A8);
        break;
      case OrderStatus.shipped:
        bg = const Color(0xFFE0E7FF);
        fg = const Color(0xFF3730A3);
        break;
      case OrderStatus.delivered:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        break;
      case OrderStatus.cancelled:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        status.value,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: fg,
        ),
      ),
    );
  }
}
