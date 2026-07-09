import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/constants/app_strings.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/core/theme/app_text_styles.dart';
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
              _buildCard(context, ctrl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, AuthController ctrl) {
    return Card(
      elevation: 5,
      shadowColor: AppColors.primaryGreen.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: ctrl.registerFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomTextField(
                label: 'Full Name',
                controller: ctrl.registerNameController,
                hintText: AppStrings.nameHint,
                icon: Icons.person_outlined,
                validator: FormValidators.name,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Email',
                controller: ctrl.registerEmailController,
                hintText: AppStrings.emailHint,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: FormValidators.email,
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
                  validator: FormValidators.confirmPassword(
                    () => ctrl.registerPasswordController.text,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Obx(
                () => CustomButton(
                  text: AppStrings.registerButton,
                  isLoading: ctrl.isLoading.value,
                  onPressed: ctrl.register,
                ),
              ),
              const SizedBox(height: 16),
              _buildLoginLink(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: AppStrings.alreadyHaveAccount,
        style: Theme.of(context).textTheme.bodyMedium,
        children: [
          TextSpan(
            text: AppStrings.loginLink,
            style: AppTextStyles.link,
            recognizer: TapGestureRecognizer()
              ..onTap = Get.back,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}