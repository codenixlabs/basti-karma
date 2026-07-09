import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/constants/app_strings.dart';
import '../../../app/core/routes/app_pages.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/shared/utils/form_validators.dart';
import '../../../app/shared/widgets/custom_button.dart';
import '../../../app/shared/widgets/custom_text_field.dart';
import '../controller/auth_controller.dart';
import '../widgets/app_header.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
          key: ctrl.loginFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: ctrl.loginEmailController,
                label: 'Email',
                hintText: AppStrings.emailHint,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: FormValidators.email,
              ),
              const SizedBox(height: 16),
              Obx(
                () => CustomTextField(
                  controller: ctrl.loginPasswordController,
                  label: 'Password',
                  hintText: AppStrings.passwordHint,
                  icon: Icons.lock_outlined,
                  obscureText: true,
                  isPasswordVisible: ctrl.loginPasswordVisible.value,
                  onVisibilityToggle: ctrl.toggleLoginPasswordVisibility,
                  validator: FormValidators.password,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.toNamed(AppRoutes.forgotPassword),
                  child: Text(
                    AppStrings.forgotPassword,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              Obx(
                () => CustomButton(
                  text: AppStrings.loginButton,
                  isLoading: ctrl.isLoading.value,
                  onPressed: ctrl.login,
                ),
              ),
              const SizedBox(height: 12),
              _buildDivider(context),
              const SizedBox(height: 12),
              CustomButton(
                text: AppStrings.registerNewAccount,
                isOutlined: true,
                onPressed: () => Get.toNamed(AppRoutes.register),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.inputBackground, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            AppStrings.newToBastikarma,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.inputBackground, thickness: 1),
        ),
      ],
    );
  }
}
