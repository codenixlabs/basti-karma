import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String label;
  final IconData icon;
  final bool obscureText;
  final VoidCallback? onVisibilityToggle;
  final bool isPasswordVisible;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Color? fillColor;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.onVisibilityToggle,
    this.isPasswordVisible = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textDarkGreen,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText && !isPasswordVisible,
          keyboardType: keyboardType,
          validator: validator,
          // Cursor matches primary green theme
          cursorColor: AppColors.primaryGreen,
          style: const TextStyle(color: AppColors.textDarkGreen, fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: AppColors.darkGrey, fontSize: 14),
            prefixIcon: Icon(icon, color: AppColors.primaryGreen, size: 20),
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                width: 1,
                color: AppColors.primaryGreen,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                width: 1,
                color: AppColors.primaryGreen,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                width: 1.5,
                color: AppColors.primaryGreen,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(width: 1, color: AppColors.errorRed),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                width: 1.5,
                color: AppColors.errorRed,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
