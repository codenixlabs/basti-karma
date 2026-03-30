import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bastikarma/features/auth/controller/auth_controller.dart';

import '../../../app/core/constants/app_strings.dart';
import '../../../app/core/theme/app_theme.dart';
import '../../../app/shared/widgets/app_header.dart';
import '../../../app/shared/widgets/custom_button.dart';
import '../../../app/shared/widgets/custom_text_field.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const AppHeader(),
                const SizedBox(height: 24),

                Card(
                  elevation: 5,
                  shadowColor: AppColors.primaryGreen.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CustomTextField(
                          label: "Full Name",
                          controller: authController.registerNameController,
                          hintText: AppStrings.nameHint,
                          icon: Icons.person_outlined,
                        ),
                        const SizedBox(height: 16),

                        // Email Field
                        CustomTextField(
                          label: "Email",
                          controller: authController.registerEmailController,
                          hintText: AppStrings.emailHint,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        Obx(
                          () => CustomTextField(
                            label: "Password",
                            controller:
                                authController.registerPasswordController,
                            hintText: AppStrings.passwordHint,
                            icon: Icons.lock_outlined,
                            obscureText: true,
                            isPasswordVisible:
                                authController.registerPasswordVisible.value,
                            onVisibilityToggle: () => authController
                                .toggleRegisterPasswordVisibility(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password Field
                        Obx(
                          () => CustomTextField(
                            label: "Confirm Password",
                            controller: authController
                                .registerConfirmPasswordController,
                            hintText: AppStrings.confirmPasswordHint,
                            icon: Icons.lock_outlined,
                            obscureText: true,
                            isPasswordVisible: authController
                                .registerConfirmPasswordVisible
                                .value,
                            onVisibilityToggle: () => authController
                                .toggleConfirmPasswordVisibility(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Register Button
                        Obx(
                          () => CustomButton(
                            text: AppStrings.registerButton,
                            isLoading: authController.isLoading.value,
                            onPressed: () => authController.register(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text.rich(
                          TextSpan(
                            text: AppStrings.alreadyHaveAccount,
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: [
                              TextSpan(
                                text: "Login",
                                style: TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.primaryGreen,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Get.offNamed('/login');
                                  },
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
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
