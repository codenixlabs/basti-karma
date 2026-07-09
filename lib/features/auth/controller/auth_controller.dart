import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/constants/app_strings.dart';
import '../../../app/core/routes/app_pages.dart';
import '../../../app/shared/utils/custom_snackbar.dart';

class AuthController extends GetxController {
  // Form keys — used by screens to trigger inline validation
  final loginFormKey = GlobalKey<FormState>();
  final registerFormKey = GlobalKey<FormState>();
  final forgotPasswordFormKey = GlobalKey<FormState>();

  // Login
  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();

  // Register
  final registerNameController = TextEditingController();
  final registerEmailController = TextEditingController();
  final registerPasswordController = TextEditingController();
  final registerConfirmPasswordController = TextEditingController();

  // Forgot password
  final forgotEmailController = TextEditingController();

  // Loading state
  final isLoading = false.obs;
  final isForgotLoading = false.obs;

  // Password visibility
  final loginPasswordVisible = false.obs;
  final registerPasswordVisible = false.obs;
  final registerConfirmPasswordVisible = false.obs;

  void toggleLoginPasswordVisibility() => loginPasswordVisible.toggle();

  void toggleRegisterPasswordVisibility() => registerPasswordVisible.toggle();

  void toggleConfirmPasswordVisibility() =>
      registerConfirmPasswordVisible.toggle();

  Future<void> login() async {
    if (loginFormKey.currentState?.validate() != true) return;

    isLoading.value = true;
    try {
      await Future.delayed(const Duration(seconds: 2));
      Get.offAllNamed(AppRoutes.home);
      CustomSnackBar.showSuccess(AppStrings.loginSuccess);
    } catch (e) {
      CustomSnackBar.showError('${AppStrings.loginFailed}: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forgotPassword() async {
    if (forgotPasswordFormKey.currentState?.validate() != true) return;

    isForgotLoading.value = true;
    try {
      await Future.delayed(const Duration(seconds: 2));
      Get.back();
      CustomSnackBar.showSuccess(AppStrings.resetLinkSent);
    } catch (e) {
      CustomSnackBar.showError('${AppStrings.resetLinkFailed}: $e');
    } finally {
      isForgotLoading.value = false;
    }
  }

  Future<void> register() async {
    if (registerFormKey.currentState?.validate() != true) return;

    isLoading.value = true;
    try {
      await Future.delayed(const Duration(seconds: 2));
      Get.offAllNamed(AppRoutes.login);
      CustomSnackBar.showSuccess(AppStrings.registerSuccessMessage);
    } catch (e) {
      CustomSnackBar.showError('${AppStrings.registrationFailed}: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    loginEmailController.dispose();
    loginPasswordController.dispose();
    registerNameController.dispose();
    registerEmailController.dispose();
    registerPasswordController.dispose();
    registerConfirmPasswordController.dispose();
    forgotEmailController.dispose();
    super.onClose();
  }
}
