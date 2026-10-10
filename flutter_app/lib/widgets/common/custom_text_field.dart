import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Form input field with label, error text, prefix icon, and optional obscure toggle.
class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool isPassword;
  final bool? obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final int maxLines;
  final int? maxLength;

  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.isPassword = false,
    this.obscureText,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.prefixIcon,
    this.suffixIcon,
    this.suffix,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText ?? widget.isPassword;
  }

  @override
  void didUpdateWidget(CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.obscureText != null && widget.obscureText != oldWidget.obscureText) {
      _obscured = widget.obscureText!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedSuffix = widget.suffix ?? widget.suffixIcon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null && widget.label!.isNotEmpty) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
        ],
        TextFormField(
          controller: widget.controller,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          enabled: widget.enabled,
          maxLines: (widget.isPassword || widget.obscureText == true) ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          onChanged: widget.onChanged,
          validator: widget.validator,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    size: 20,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  )
                : null,
            suffixIcon: widget.isPassword && resolvedSuffix == null
                ? IconButton(
                    icon: Icon(
                      _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscured = !_obscured;
                      });
                    },
                  )
                : resolvedSuffix,
          ),
        ),
      ],
    );
  }
}
