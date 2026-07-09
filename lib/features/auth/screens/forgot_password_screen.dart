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
                AppStrings.forgotPasswordSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: ctrl.forgotEmailController,
                label: 'Email',
                hintText: AppStrings.emailHint,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: FormValidators.email,
              ),
              const SizedBox(height: 24),
              Obx(
                () => CustomButton(
                  text: AppStrings.sendResetLink,
                  isLoading: ctrl.isForgotLoading.value,
                  onPressed: ctrl.forgotPassword,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: Get.back,
                  child: Text(
                    AppStrings.backToLogin,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
