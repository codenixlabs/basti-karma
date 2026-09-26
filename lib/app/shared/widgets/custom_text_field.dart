import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_text_styles.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String label;
  final IconData? icon;
  final bool obscureText;
  final VoidCallback? onVisibilityToggle;
  final bool isPasswordVisible;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final bool enabled;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final Color? fillColor;
  final AutovalidateMode autovalidateMode;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.label = '',
    this.icon,
    this.obscureText = false,
    this.onVisibilityToggle,
    this.isPasswordVisible = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.readOnly = false,
    this.onChanged,
    this.focusNode,
    this.validator,
    this.fillColor,
    this.autovalidateMode = AutovalidateMode.onUnfocus,
    this.suffixIcon,
  });

  static OutlineInputBorder _border(Color color, {double width = 1.0}) =>
      OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(width: width, color: color),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: AppTextStyles.fieldLabel,
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          readOnly: readOnly,
          obscureText: obscureText && !isPasswordVisible,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          autofillHints: autofillHints,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          autovalidateMode: autovalidateMode,
          validator: validator,
          cursorColor: AppColors.primaryGreen,
          style: AppTextStyles.fieldInput.copyWith(
            color: readOnly
                ? AppColors.textDarkGreen.withValues(alpha: 0.8)
                : null,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.fieldHint,
            prefixIcon: icon != null
                ? Icon(icon, color: AppColors.primaryGreen, size: 20)
                : null,
            suffixIcon: suffixIcon ??
                (obscureText
                    ? IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: AppColors.primaryGreen,
                          size: 20,
                        ),
                        onPressed: onVisibilityToggle,
                        tooltip: isPasswordVisible
                            ? 'Hide password'
                            : 'Show password',
                      )
                    : null),
            filled: true,
            fillColor: !enabled || readOnly
                ? (fillColor ?? AppColors.lightGrey.withValues(alpha: 0.35))
                : (fillColor ?? AppColors.background.withValues(alpha: 0.3)),
            border: _border(AppColors.primaryGreen),
            enabledBorder: readOnly
                ? _border(AppColors.primaryGreen.withValues(alpha: 0.2))
                : _border(AppColors.primaryGreen),
            focusedBorder: readOnly
                ? _border(AppColors.primaryGreen.withValues(alpha: 0.2))
                : _border(AppColors.primaryGreen, width: 1.5),
            disabledBorder: _border(AppColors.lightGrey),
            errorBorder: _border(AppColors.errorRed),
            focusedErrorBorder: _border(AppColors.errorRed, width: 1.5),
          ),
        ),
      ],
    );
  }
}