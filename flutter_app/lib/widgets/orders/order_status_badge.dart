import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../theme/app_theme.dart';

/// Pill badge displaying order lifecycle state with semantic color coding.
class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    Color fg;
    Color border;

    switch (status) {
      case OrderStatus.pending:
        bg = isDark ? const Color(0xFF38230B) : const Color(0xFFFEF3C7);
        fg = isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E);
        border = isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A);
        break;
      case OrderStatus.confirmed:
        bg = isDark ? const Color(0xFF10254C) : const Color(0xFFDBEAFE);
        fg = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E40AF);
        border = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBFDBFE);
        break;
      case OrderStatus.processing:
        bg = isDark ? const Color(0xFF2E1045) : const Color(0xFFF3E8FF);
        fg = isDark ? const Color(0xFFC084FC) : const Color(0xFF6B21A8);
        border = isDark ? const Color(0xFF581C87) : const Color(0xFFE9D5FF);
        break;
      case OrderStatus.shipped:
        bg = isDark ? const Color(0xFF1E1B4B) : const Color(0xFFE0E7FF);
        fg = isDark ? const Color(0xFF818CF8) : const Color(0xFF3730A3);
        border = isDark ? const Color(0xFF312E81) : const Color(0xFFC7D2FE);
        break;
      case OrderStatus.delivered:
        bg = isDark ? const Color(0xFF063319) : const Color(0xFFDCFCE7);
        fg = isDark ? const Color(0xFF34D399) : const Color(0xFF166534);
        border = isDark ? const Color(0xFF065F46) : const Color(0xFFBBF7D0);
        break;
      case OrderStatus.cancelled:
        bg = isDark ? const Color(0xFF2C1316) : const Color(0xFFFEF2F2);
        fg = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
        border = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: border, width: 1),
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
