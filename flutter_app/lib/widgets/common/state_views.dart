import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'custom_button.dart';

/// Clean loading state view with understated progress spinner.
class LoadingView extends StatelessWidget {
  final String? message;

  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 36,
              width: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                ),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppTheme.space16),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Actionable empty state view explaining context and providing next step.
class EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space32, vertical: AppTheme.space48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceWarm,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
              ),
            ),
            const SizedBox(height: AppTheme.space24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppTheme.space24),
              CustomButton(
                text: actionText!,
                onPressed: onAction,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Actionable error state view with retry action.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String retryText;

  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.retryText = 'Try Again',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: AppTheme.error,
            ),
            const SizedBox(height: AppTheme.space16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.space24),
              CustomButton(
                text: retryText,
                onPressed: onRetry,
                variant: ButtonVariant.secondary,
                width: 160,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Success feedback view with confirmation checkmark.
class SuccessView extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onAction;

  const SuccessView({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space32, vertical: AppTheme.space48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: const BoxDecoration(
                color: AppTheme.successContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 38,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(height: AppTheme.space24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.space32),
            CustomButton(
              text: actionText,
              onPressed: onAction,
            ),
          ],
        ),
      ),
    );
  }
}
