import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';

/// Reusable modal dialog following BastiKarma's standard design system.
/// Matches the look, padding, border radius, typography, and button styling
/// of the clinical session logout dialog.
class AppDialog extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String content;
  final Widget? customContent;
  final String? cancelText;
  final VoidCallback? onCancel;
  final String confirmText;
  final VoidCallback? onConfirm;
  final Color? confirmColor;
  final IconData? confirmIcon;

  const AppDialog({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.content = '',
    this.customContent,
    this.cancelText = 'Cancel',
    this.onCancel,
    this.confirmText = 'Confirm',
    this.onConfirm,
    this.confirmColor,
    this.confirmIcon,
  });

  /// Shows a confirmation dialog and returns true if confirmed, false if cancelled.
  static Future<bool?> showConfirmation({
    required String title,
    required String content,
    IconData? icon,
    Color? iconColor,
    String? cancelText = 'Cancel',
    String confirmText = 'Confirm',
    Color? confirmColor,
    IconData? confirmIcon,
    bool barrierDismissible = true,
  }) {
    return Get.dialog<bool>(
      AppDialog(
        title: title,
        content: content,
        icon: icon,
        iconColor: iconColor,
        cancelText: cancelText,
        confirmText: confirmText,
        confirmColor: confirmColor,
        confirmIcon: confirmIcon,
        onCancel: () => Get.back(result: false),
        onConfirm: () => Get.back(result: true),
      ),
      barrierDismissible: barrierDismissible,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.white,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: iconColor ?? AppColors.primaryGreen,
              size: 22,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textDarkGreen,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: customContent ??
          Text(
            content,
            style: const TextStyle(
              color: AppColors.darkGrey,
              fontSize: 14,
              height: 1.5,
            ),
          ),
      actions: [
        if (cancelText != null)
          TextButton(
            onPressed: onCancel ?? () => Get.back(result: false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.darkGrey,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              cancelText!,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ElevatedButton(
          onPressed: onConfirm ?? () => Get.back(result: true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor ?? AppColors.primaryGreen,
            foregroundColor: AppColors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (confirmIcon != null) ...[
                Icon(confirmIcon, size: 16),
                const SizedBox(width: 6),
              ],
              Text(
                confirmText,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
