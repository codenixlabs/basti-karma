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
  final String? Function(String?)? validator;
  final Color? fillColor;
  final AutovalidateMode autovalidateMode;

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
    this.validator,
    this.fillColor,
    this.autovalidateMode = AutovalidateMode.onUnfocus,
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
          obscureText: obscureText && !isPasswordVisible,
          keyboardType: keyboardType,
          autovalidateMode: autovalidateMode,
          validator: validator,
          cursorColor: AppColors.primaryGreen,
          style: AppTextStyles.fieldInput,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTextStyles.fieldHint,
            prefixIcon: icon != null
                ? Icon(icon, color: AppColors.primaryGreen, size: 20)
                : null,
            suffixIcon: obscureText
                ? GestureDetector(
                    onTap: onVisibilityToggle,
                    child: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.primaryGreen,
                      size: 20,
                    ),
                  )
                : null,
            filled: true,
            fillColor: fillColor ?? AppColors.background.withValues(alpha: 0.3),
            border: _border(AppColors.primaryGreen),
            enabledBorder: _border(AppColors.primaryGreen),
            focusedBorder: _border(AppColors.primaryGreen, width: 1.5),
            errorBorder: _border(AppColors.errorRed),
            focusedErrorBorder: _border(AppColors.errorRed, width: 1.5),
          ),
        ),
      ],
    );
  }
}