import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/constants/app_strings.dart';
import '../../../app/core/theme/app_text_styles.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/shared/utils/form_validators.dart';
import '../../../app/shared/widgets/custom_button.dart';
import '../../../app/shared/widgets/custom_text_field.dart';
import '../controller/auth_controller.dart';
import '../widgets/app_header.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

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
              Obx(() => ctrl.isRegisterOtpSent.value
                  ? _buildOtpCard(context, ctrl)
                  : _buildRegistrationCard(context, ctrl)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationCard(BuildContext context, AuthController ctrl) {
    return Card(
      elevation: 5,
      shadowColor: AppColors.primaryGreen.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: AutofillGroup(
          child: Form(
            key: ctrl.registerFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textDarkGreen,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter your details to receive an OTP verification code',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.darkGrey,
                      ),
                ),
                const SizedBox(height: 20),
                Obx(
                  () => CustomTextField(
                    label: 'Full Name',
                    controller: ctrl.registerNameController,
                    hintText: AppStrings.nameHint,
                    icon: Icons.person_outlined,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    enabled: !ctrl.isLoading.value,
                    validator: FormValidators.name,
                  ),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => CustomTextField(
                    label: 'Email',
                    controller: ctrl.registerEmailController,
                    hintText: AppStrings.emailHint,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    enabled: !ctrl.isLoading.value,
                    validator: FormValidators.email,
                  ),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => CustomTextField(
                    label: 'Password',
                    controller: ctrl.registerPasswordController,
                    hintText: AppStrings.passwordHint,
                    icon: Icons.lock_outlined,
                    obscureText: true,
                    isPasswordVisible: ctrl.registerPasswordVisible.value,
                    onVisibilityToggle: ctrl.toggleRegisterPasswordVisibility,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    enabled: !ctrl.isLoading.value,
                    validator: FormValidators.password,
                  ),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => CustomTextField(
                    label: 'Confirm Password',
                    controller: ctrl.registerConfirmPasswordController,
                    hintText: AppStrings.confirmPasswordHint,
                    icon: Icons.lock_outlined,
                    obscureText: true,
                    isPasswordVisible: ctrl.registerConfirmPasswordVisible.value,
                    onVisibilityToggle: ctrl.toggleConfirmPasswordVisibility,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    enabled: !ctrl.isLoading.value,
                    onFieldSubmitted: (_) => ctrl.startSignupFlow(),
                    validator: FormValidators.confirmPassword(
                      () => ctrl.registerPasswordController.text,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Obx(
                  () => Column(
                    children: [
                      CustomButton(
                        text: 'Send Verification OTP',
                        isLoading: ctrl.isLoading.value,
                        onPressed: ctrl.startSignupFlow,
                      ),
                      if (ctrl.isLoading.value &&
                          ctrl.loadingStatus.value.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          ctrl.loadingStatus.value,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildLoginLink(context, ctrl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpCard(BuildContext context, AuthController ctrl) {
    return Card(
      elevation: 5,
      shadowColor: AppColors.primaryGreen.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: ctrl.registerOtpFormKey,
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
                  Icons.mark_email_read_outlined,
                  color: AppColors.primaryGreen,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Verify Email',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textDarkGreen,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to\n${ctrl.registerEmailController.text.trim()}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkGrey,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'Verification Code',
                controller: ctrl.registerOtpController,
                hintText: 'Enter 6-digit OTP',
                icon: Icons.pin_outlined,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                enabled: !ctrl.isLoading.value,
                onFieldSubmitted: (_) => ctrl.completeSignup(),
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
                final countdown = ctrl.registerOtpCountdown.value;
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
                      ctrl.isLoading.value ? null : ctrl.resendSignupOtp,
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
                () => Column(
                  children: [
                    CustomButton(
                      text: 'Complete Registration',
                      isLoading: ctrl.isLoading.value,
                      onPressed: ctrl.completeSignup,
                    ),
                    if (ctrl.isLoading.value &&
                        ctrl.loadingStatus.value.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        ctrl.loadingStatus.value,
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed:
                    ctrl.isLoading.value ? null : ctrl.cancelRegisterOtp,
                child: const Text(
                  'Edit Registration Info',
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

  Widget _buildLoginLink(BuildContext context, AuthController ctrl) {
    return Obx(
      () => Text.rich(
        TextSpan(
          text: AppStrings.alreadyHaveAccount,
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: AppStrings.loginLink,
              style: AppTextStyles.link.copyWith(
                color: ctrl.isLoading.value
                    ? AppColors.darkGrey
                    : AppColors.primaryGreen,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  if (!ctrl.isLoading.value) {
                    Get.back();
                  }
                },
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}