import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/constants/app_strings.dart';
import '../../../app/core/routes/app_pages.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/shared/utils/app_navigation.dart';
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
        child: AutofillGroup(
          child: Form(
            key: ctrl.loginFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => CustomTextField(
                    controller: ctrl.loginEmailController,
                    label: 'Email',
                    hintText: AppStrings.emailHint,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.email,
                      AutofillHints.username,
                    ],
                    enabled: !ctrl.isLoading.value,
                    validator: FormValidators.email,
                  ),
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
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    enabled: !ctrl.isLoading.value,
                    onFieldSubmitted: (_) => ctrl.login(),
                    validator: FormValidators.password,
                  ),
                ),
                Obx(
                  () => Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: ctrl.isLoading.value
                          ? null
                          : () => AppNavigation.toNamed(AppRoutes.forgotPassword),
                      child: Text(
                        AppStrings.forgotPassword,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ctrl.isLoading.value
                                  ? AppColors.darkGrey
                                  : null,
                            ),
                      ),
                    ),
                  ),
                ),
                Obx(
                  () => Column(
                    children: [
                      CustomButton(
                        text: AppStrings.loginButton,
                        isLoading: ctrl.isLoading.value,
                        onPressed: ctrl.login,
                      ),
                      if (ctrl.isLoading.value &&
                          ctrl.loadingStatus.value.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          ctrl.loadingStatus.value,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildDivider(context),
                const SizedBox(height: 12),
                Obx(
                  () => CustomButton(
                    text: AppStrings.registerNewAccount,
                    isOutlined: true,
                    isEnabled: !ctrl.isLoading.value,
                    onPressed: () => AppNavigation.toNamed(AppRoutes.register),
                  ),
                ),
              ],
            ),
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
