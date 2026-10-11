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
  TextEditingController? _internalController;
  TextEditingController get _effectiveController =>
      widget.controller ?? (_internalController ??= TextEditingController());

  late bool _obscured;
  late String _lastText;
  String? _externalError;
  String? _validatorError;
  bool _suppressError = false;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText ?? widget.isPassword;
    _externalError = widget.errorText;
    _lastText = _effectiveController.text;
    _effectiveController.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.obscureText != null && widget.obscureText != oldWidget.obscureText) {
      _obscured = widget.obscureText!;
    }
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChanged);
      _effectiveController.addListener(_handleControllerChanged);
      _lastText = _effectiveController.text;
    }
    if (widget.errorText != oldWidget.errorText) {
      _externalError = widget.errorText;
      if (widget.errorText != null) {
        _suppressError = false;
      }
    }
  }

  @override
  void dispose() {
    if (widget.controller != null) {
      widget.controller!.removeListener(_handleControllerChanged);
    } else {
      _internalController?.removeListener(_handleControllerChanged);
      _internalController?.dispose();
    }
    super.dispose();
  }

  void _handleControllerChanged() {
    if (_effectiveController.text != _lastText) {
      _lastText = _effectiveController.text;
      _handleEditingAction();
    }
  }

  void _handleEditingAction() {
    if (!_suppressError || _externalError != null) {
      setState(() {
        _suppressError = true;
        _externalError = null;
      });
    }
  }

  String? _validate(String? value) {
    // Action button / form submission triggered validation
    _suppressError = false;
    if (widget.validator != null) {
      _validatorError = widget.validator!(value);
      return _validatorError;
    }
    return null;
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
        FormField<String>(
          initialValue: _effectiveController.text,
          validator: _validate,
          builder: (FormFieldState<String> fieldState) {
            final effectiveError = _suppressError
                ? null
                : (_externalError ?? _validatorError ?? fieldState.errorText);

            return TextField(
              controller: _effectiveController,
              obscureText: _obscured,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              enabled: widget.enabled,
              maxLines: (widget.isPassword || widget.obscureText == true) ? 1 : widget.maxLines,
              maxLength: widget.maxLength,
              onChanged: (val) {
                fieldState.didChange(val);
                _handleEditingAction();
                widget.onChanged?.call(val);
              },
              style: TextStyle(
                fontSize: 15,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                errorText: effectiveError,
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
            );
          },
        ),
      ],
    );
  }
}
