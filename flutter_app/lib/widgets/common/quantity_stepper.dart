import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Stepper control allowing users to increment/decrement quantities with stock limits.
class QuantityStepper extends StatelessWidget {
  final int value;
  final int max;
  final int min;
  final ValueChanged<int> onChanged;
  final bool enabled;

  const QuantityStepper({
    super.key,
    required this.value,
    required this.max,
    this.min = 1,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final canDecrement = enabled && value > min;
    final canIncrement = enabled && value < max;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            enabled: canDecrement,
            onPressed: () => onChanged(value - 1),
            isDark: isDark,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            enabled: canIncrement,
            onPressed: () => onChanged(value + 1),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;
  final bool isDark;

  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space8),
        child: Icon(
          icon,
          size: 16,
          color: enabled
              ? (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)
              : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        ),
      ),
    );
  }
}
