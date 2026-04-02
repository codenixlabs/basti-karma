import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/constants/app_strings.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/shared/utils/custom_snackbar.dart';
import '../widgets/app_header.dart';
import '../../../app/shared/widgets/custom_button.dart';
import '../../../app/shared/widgets/custom_text_field.dart';
import '../controller/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const AppHeader(),
                const SizedBox(height: 24),
                Card(
                  elevation: 5,
                  shadowColor: AppColors.primaryGreen.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextField(
                          controller: authController.loginEmailController,
                          label: "Email",
                          hintText: AppStrings.emailHint,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        Obx(
                          () => CustomTextField(
                            controller: authController.loginPasswordController,
                            hintText: AppStrings.passwordHint,
                            icon: Icons.lock_outlined,
                            label: "Password",
                            obscureText: true,
                            isPasswordVisible:
                                authController.loginPasswordVisible.value,
                            onVisibilityToggle: () =>
                                authController.toggleLoginPasswordVisibility(),
                          ),
                        ),
                        // Forgot Password Button
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              CustomSnackBar.showInfo(
                                'Forgot Password feature coming soon!',
                              );
                            },
                            child: Text(
                              AppStrings.forgotPassword,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                        // Login Button
                        Obx(
                          () => CustomButton(
                            text: AppStrings.loginButton,
                            isLoading: authController.isLoading.value,
                            onPressed: () => authController.login(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Divider with Text
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: AppColors.inputBackground,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                AppStrings.newToBastikarma,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: AppColors.inputBackground,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        CustomButton(
                          text: AppStrings.registerNewAccount,
                          isOutlined: true,
                          onPressed: () {
                            Get.offNamed('/register');
                          },
                        ),
                      ],
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
