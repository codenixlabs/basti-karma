import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bastikarma/theme/app_theme.dart';

class CustomSnackBar {
  // Success Snackbar
  static void showSuccess(String message, {String? title}) {
    Get.snackbar(
      title ?? 'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.successGreen,
      colorText: AppColors.white,
      borderRadius: 20,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      duration: const Duration(seconds: 2),
      icon: const Icon(
        Icons.check_circle_outline,
        color: AppColors.white,
        size: 28,
      ),
      boxShadows: [
        BoxShadow(
          color: AppColors.successGreen.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      animationDuration: const Duration(milliseconds: 1000),
      forwardAnimationCurve: Curves.easeOut,
      reverseAnimationCurve: Curves.easeIn,
      dismissDirection: DismissDirection.horizontal,
      isDismissible: true,
    );
  }

  // Error Snackbar
  static void showError(String message, {String? title}) {
    Get.snackbar(
      title ?? 'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.errorRed,
      colorText: AppColors.white,
      borderRadius: 20,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.error_outline, color: AppColors.white, size: 28),
      boxShadows: [
        BoxShadow(
          color: AppColors.errorRed.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      animationDuration: const Duration(milliseconds: 1000),
      forwardAnimationCurve: Curves.easeOut,
      reverseAnimationCurve: Curves.easeIn,
      dismissDirection: DismissDirection.horizontal,
      isDismissible: true,
    );
  }

  // Info Snackbar
  static void showInfo(String message, {String? title}) {
    Get.snackbar(
      title ?? 'Info',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primaryGreen,
      colorText: AppColors.white,
      borderRadius: 20,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.info_outline, color: AppColors.white, size: 28),
      boxShadows: [
        BoxShadow(
          color: AppColors.primaryGreen.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      animationDuration: const Duration(milliseconds: 1000),
      forwardAnimationCurve: Curves.easeOut,
      reverseAnimationCurve: Curves.easeIn,
      dismissDirection: DismissDirection.horizontal,
      isDismissible: true,
    );
  }

  // Warning Snackbar
  static void showWarning(String message, {String? title}) {
    Get.snackbar(
      title ?? 'Warning',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFF39C12),
      colorText: AppColors.white,
      borderRadius: 20,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      duration: const Duration(seconds: 2),
      icon: const Icon(
        Icons.warning_outlined,
        color: AppColors.white,
        size: 28,
      ),
      boxShadows: [
        BoxShadow(
          color: const Color(0xFFF39C12).withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      animationDuration: const Duration(milliseconds: 1000),
      forwardAnimationCurve: Curves.easeOut,
      reverseAnimationCurve: Curves.easeIn,
      dismissDirection: DismissDirection.horizontal,
      isDismissible: true,
    );
  }
}
