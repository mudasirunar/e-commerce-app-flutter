import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Luxury styled confirmation/alert dialog with centered header, icon badge,
/// centered description, balanced side-by-side buttons, and optional async submission loading state.
class AppConfirmationDialog extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final Widget? customContent;
  final Future<bool?> Function()? onAsyncConfirm;

  const AppConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.iconColor,
    this.iconBackgroundColor,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.customContent,
    this.onAsyncConfirm,
  });

  /// Displays the dialog and returns `true` if confirmed, `false` or `null` if cancelled.
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.info_outline_rounded,
    Color? iconColor,
    Color? iconBackgroundColor,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    Widget? customContent,
    Future<bool?> Function()? onAsyncConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AppConfirmationDialog(
        title: title,
        message: message,
        icon: icon,
        iconColor: iconColor,
        iconBackgroundColor: iconBackgroundColor,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        customContent: customContent,
        onAsyncConfirm: onAsyncConfirm,
      ),
    );
  }

  @override
  State<AppConfirmationDialog> createState() => _AppConfirmationDialogState();
}

class _AppConfirmationDialogState extends State<AppConfirmationDialog> {
  bool _isSubmitting = false;

  Future<void> _handleConfirm() async {
    if (widget.onAsyncConfirm != null) {
      setState(() => _isSubmitting = true);
      try {
        final result = await widget.onAsyncConfirm!();
        if (!mounted) return;
        Navigator.of(context).pop(result ?? true);
      } catch (_) {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectivePrimary = widget.isDestructive ? AppTheme.error : theme.colorScheme.primary;
    final effectiveIconColor = widget.iconColor ?? effectivePrimary;
    final effectiveIconBg = widget.iconBackgroundColor ??
        (widget.isDestructive
            ? AppTheme.error.withValues(alpha: 0.12)
            : theme.colorScheme.primary.withValues(alpha: 0.12));

    return PopScope(
      canPop: !_isSubmitting,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        elevation: 6,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Center top circular icon badge
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: effectiveIconBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    widget.icon,
                    size: 28,
                    color: effectiveIconColor,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Centered Title
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 19,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),

              // Centered Message or custom content
              if (widget.customContent != null)
                widget.customContent!
              else
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              const SizedBox(height: 24),

              // Symmetrical side-by-side action buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.18)
                                : const Color(0xFFD6D3D1),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.cancelLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _isSubmitting
                                ? (isDark ? Colors.white24 : Colors.black26)
                                : (isDark ? Colors.white70 : const Color(0xFF44403C)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleConfirm,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          backgroundColor: effectivePrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                widget.confirmLabel,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
