import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/constants/app_strings.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/shared/utils/form_validators.dart';
import '../../../app/shared/widgets/custom_button.dart';
import '../../../app/shared/widgets/custom_text_field.dart';
import '../controller/auth_controller.dart';
import '../widgets/app_header.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AuthController>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const AppHeader(),
              const SizedBox(height: 24),
              Obx(() {
                switch (ctrl.forgotStep.value) {
                  case 1:
                    return _buildOtpStep(context, ctrl);
                  case 2:
                    return _buildNewPasswordStep(context, ctrl);
                  case 0:
                  default:
                    return _buildEmailStep(context, ctrl);
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 0: Request Reset OTP ───────────────────────────────────────────────

  Widget _buildEmailStep(BuildContext context, AuthController ctrl) {
    return Card(
      elevation: 5,
      shadowColor: AppColors.primaryGreen.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: AutofillGroup(
          child: Form(
            key: ctrl.forgotPasswordFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.forgotPasswordTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textDarkGreen,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your registered email address to receive a 6-digit OTP code.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Obx(
                  () => CustomTextField(
                    controller: ctrl.forgotEmailController,
                    label: 'Email',
                    hintText: AppStrings.emailHint,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    enabled: !ctrl.isForgotLoading.value,
                    onFieldSubmitted: (_) => ctrl.sendForgotPasswordOtp(),
                    validator: FormValidators.email,
                  ),
                ),
                const SizedBox(height: 24),
                Obx(
                  () => CustomButton(
                    text: 'Send Reset OTP',
                    isLoading: ctrl.isForgotLoading.value,
                    onPressed: ctrl.sendForgotPasswordOtp,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Obx(
                    () => TextButton(
                      onPressed:
                          ctrl.isForgotLoading.value ? null : Get.back,
                      child: Text(
                        AppStrings.backToLogin,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ctrl.isForgotLoading.value
                                  ? AppColors.darkGrey
                                  : AppColors.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 1: Verify OTP ──────────────────────────────────────────────────────

  Widget _buildOtpStep(BuildContext context, AuthController ctrl) {
    return Card(
      elevation: 5,
      shadowColor: AppColors.primaryGreen.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: ctrl.forgotOtpFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.primaryGreen,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Verify Reset OTP',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textDarkGreen,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to\n${ctrl.forgotEmailController.text.trim()}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkGrey,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'Verification Code',
                controller: ctrl.forgotOtpController,
                hintText: 'Enter 6-digit OTP',
                icon: Icons.pin_outlined,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                enabled: !ctrl.isForgotLoading.value,
                onFieldSubmitted: (_) => ctrl.verifyForgotOtp(),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'OTP is required';
                  }
                  if (val.trim().length != 6) {
                    return 'Must be 6 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Obx(() {
                final countdown = ctrl.forgotOtpCountdown.value;
                if (countdown > 0) {
                  return Text(
                    'Resend code in ${countdown}s',
                    style: const TextStyle(
                      color: AppColors.darkGrey,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }
                return TextButton(
                  onPressed:
                      ctrl.isForgotLoading.value ? null : ctrl.resendForgotOtp,
                  child: const Text(
                    'Resend Code',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
              Obx(
                () => CustomButton(
                  text: 'Verify Code',
                  isLoading: ctrl.isForgotLoading.value,
                  onPressed: ctrl.verifyForgotOtp,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: ctrl.isForgotLoading.value
                    ? null
                    : () => ctrl.forgotStep.value = 0,
                child: const Text(
                  'Change Email',
                  style: TextStyle(
                    color: AppColors.darkGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 2: Set New Password ────────────────────────────────────────────────

  Widget _buildNewPasswordStep(BuildContext context, AuthController ctrl) {
    return Card(
      elevation: 5,
      shadowColor: AppColors.primaryGreen.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: AutofillGroup(
          child: Form(
            key: ctrl.forgotResetFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set New Password',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textDarkGreen,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a secure new password with at least 6 characters.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Obx(
                  () => CustomTextField(
                    label: 'New Password',
                    controller: ctrl.forgotNewPasswordController,
                    hintText: 'Enter new password',
                    icon: Icons.lock_outlined,
                    obscureText: true,
                    isPasswordVisible: ctrl.forgotNewPasswordVisible.value,
                    onVisibilityToggle: ctrl.toggleForgotNewPasswordVisibility,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    enabled: !ctrl.isForgotLoading.value,
                    validator: FormValidators.password,
                  ),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => CustomTextField(
                    label: 'Confirm New Password',
                    controller: ctrl.forgotConfirmPasswordController,
                    hintText: 'Re-enter new password',
                    icon: Icons.lock_outlined,
                    obscureText: true,
                    isPasswordVisible:
                        ctrl.forgotConfirmPasswordVisible.value,
                    onVisibilityToggle:
                        ctrl.toggleForgotConfirmPasswordVisibility,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    enabled: !ctrl.isForgotLoading.value,
                    onFieldSubmitted: (_) => ctrl.submitResetPassword(),
                    validator: FormValidators.confirmPassword(
                      () => ctrl.forgotNewPasswordController.text,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Obx(
                  () => CustomButton(
                    text: 'Reset Password',
                    isLoading: ctrl.isForgotLoading.value,
                    onPressed: ctrl.submitResetPassword,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: ctrl.isForgotLoading.value
                        ? null
                        : () {
                            ctrl.resetForgotPasswordFlow();
                            Get.back();
                          },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.darkGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
