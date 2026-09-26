import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/theme/app_theme.dart';
import '../../../app/shared/widgets/custom_button.dart';
import '../../../app/shared/widgets/custom_text_field.dart';
import '../controller/profile_controller.dart';

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());

    // Reset password form state on entry
    controller.resetChangePasswordForm();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.white,
          elevation: 0,
          title: const Text(
            'Change Password',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Get.back(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Security Info Card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryGreen.withValues(alpha: 0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: AppColors.primaryGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Account Protection',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDarkGreen,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Choose a secure password to safeguard patient and clinical records. Passwords must be at least 6 characters.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.darkGrey.withValues(alpha: 0.9),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Form Card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(
                        () => CustomTextField(
                          controller: controller.newPasswordController,
                          label: 'New Password',
                          hintText: 'Enter new password',
                          icon: Icons.lock_outline_rounded,
                          obscureText: true,
                          isPasswordVisible:
                              !controller.isNewPasswordObscured.value,
                          onVisibilityToggle:
                              controller.toggleNewPasswordVisibility,
                          textInputAction: TextInputAction.next,
                          fillColor: AppColors.background.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Obx(
                        () => CustomTextField(
                          controller: controller.confirmPasswordController,
                          label: 'Confirm New Password',
                          hintText: 'Re-enter new password',
                          icon: Icons.lock_reset_rounded,
                          obscureText: true,
                          isPasswordVisible:
                              !controller.isConfirmPasswordObscured.value,
                          onVisibilityToggle:
                              controller.toggleConfirmPasswordVisibility,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) async {
                            final ok = await controller.changePassword();
                            if (ok) Get.back();
                          },
                          fillColor: AppColors.background.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Helper requirements
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 16,
                              color: AppColors.primaryGreen,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Minimum length: 6 characters',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.darkGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Obx(() {
                        final error = controller.passwordErrorMessage.value;
                        if (error == null || error.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.errorRed,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  error,
                                  style: const TextStyle(
                                    color: AppColors.errorRed,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 28),
                      Obx(
                        () => CustomButton(
                          text: 'Update Password',
                          isLoading: controller.isSavingPassword.value,
                          isEnabled: !controller.isSavingPassword.value,
                          onPressed: () async {
                            final success = await controller.changePassword();
                            if (success) {
                              Get.back();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
