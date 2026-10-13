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

    final colors = AppTheme.orderStatusChipColors(status, isDark: isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Text(
        status.value,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: colors.fg,
        ),
      ),
    );
  }
}
