import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum ButtonVariant { primary, secondary, text }

/// Reusable styled button supporting primary (terracotta), secondary (outlined),
/// and text variants with loading state and accessible touch targets.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant variant;
  final IconData? icon;
  final double height;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.height = 48.0,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final childWidget = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == ButtonVariant.primary
                    ? (isDark ? Colors.black : Colors.white)
                    : theme.colorScheme.primary,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: AppTheme.space8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: _getTextColor(theme, isDark),
                ),
              ),
            ],
          );

    final sizeConstraint = Size(width ?? double.infinity, height);

    switch (variant) {
      case ButtonVariant.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: sizeConstraint,
            backgroundColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
            foregroundColor: isDark ? Colors.black : Colors.white,
            disabledBackgroundColor: isDark
                ? AppTheme.darkBorder
                : AppTheme.lightBorder,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
          ),
          child: childWidget,
        );

      case ButtonVariant.secondary:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: sizeConstraint,
            side: BorderSide(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              width: 1.2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
          ),
          child: childWidget,
        );

      case ButtonVariant.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            minimumSize: sizeConstraint,
            foregroundColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
          ),
          child: childWidget,
        );
    }
  }

  Color _getTextColor(ThemeData theme, bool isDark) {
    if (onPressed == null) {
      return isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    }
    switch (variant) {
      case ButtonVariant.primary:
        return isDark ? Colors.black : Colors.white;
      case ButtonVariant.secondary:
        return isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
      case ButtonVariant.text:
        return isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    }
  }
}
