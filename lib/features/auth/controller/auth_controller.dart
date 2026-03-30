import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../app/shared/utils/custom_snackbar.dart';

class AuthController extends GetxController {
  // Login Screen Controllers
  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();

  // Register Screen Controllers
  final registerNameController = TextEditingController();
  final registerEmailController = TextEditingController();
  final registerPasswordController = TextEditingController();
  final registerConfirmPasswordController = TextEditingController();

  // Loading state
  final isLoading = false.obs;

  // Form visibility toggles
  final loginPasswordVisible = false.obs;
  final registerPasswordVisible = false.obs;
  final registerConfirmPasswordVisible = false.obs;

  // Toggle password visibility for login
  void toggleLoginPasswordVisibility() {
    loginPasswordVisible.toggle();
  }

  // Toggle password visibility for register
  void toggleRegisterPasswordVisibility() {
    registerPasswordVisible.toggle();
  }

  // Toggle confirm password visibility
  void toggleConfirmPasswordVisibility() {
    registerConfirmPasswordVisible.toggle();
  }

  // Login method
  Future<void> login() async {
    // Validate inputs
    if (!_validateLoginInputs()) {
      return;
    }

    isLoading.value = true;
    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 2));

      // Success - navigate to home
      Get.offAllNamed('/home');

      // Clear controllers
      _clearLoginControllers();

      CustomSnackBar.showSuccess('Login successful!');
    } catch (e) {
      CustomSnackBar.showError('Login failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Register method
  Future<void> register() async {
    // Validate inputs
    if (!_validateRegisterInputs()) {
      return;
    }

    isLoading.value = true;
    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 2));

      // Success - navigate to login or home
      Get.offAllNamed('/login');

      // Clear controllers
      _clearRegisterControllers();

      CustomSnackBar.showSuccess('Registration successful! Please login.');
    } catch (e) {
      CustomSnackBar.showError('Registration failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Validate login inputs
  bool _validateLoginInputs() {
    if (loginEmailController.text.isEmpty) {
      CustomSnackBar.showError('Email is required');
      return false;
    }

    if (!_isValidEmail(loginEmailController.text)) {
      CustomSnackBar.showError('Please enter a valid email');
      return false;
    }

    if (loginPasswordController.text.isEmpty) {
      CustomSnackBar.showError('Password is required');
      return false;
    }

    if (loginPasswordController.text.length < 6) {
      CustomSnackBar.showError('Password must be at least 6 characters');
      return false;
    }

    return true;
  }

  // Validate register inputs
  bool _validateRegisterInputs() {
    if (registerNameController.text.isEmpty) {
      CustomSnackBar.showError('Name is required');
      return false;
    }

    if (registerEmailController.text.isEmpty) {
      CustomSnackBar.showError('Email is required');
      return false;
    }

    if (!_isValidEmail(registerEmailController.text)) {
      CustomSnackBar.showError('Please enter a valid email');
      return false;
    }

    if (registerPasswordController.text.isEmpty) {
      CustomSnackBar.showError('Password is required');
      return false;
    }

    if (registerPasswordController.text.length < 6) {
      CustomSnackBar.showError('Password must be at least 6 characters');
      return false;
    }

    if (registerConfirmPasswordController.text.isEmpty) {
      CustomSnackBar.showError('Please confirm your password');
      return false;
    }

    if (registerPasswordController.text !=
        registerConfirmPasswordController.text) {
      CustomSnackBar.showError('Passwords do not match');
      return false;
    }

    return true;
  }

  // Email validation helper
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Clear login controllers
  void _clearLoginControllers() {
    loginEmailController.clear();
    loginPasswordController.clear();
  }

  // Clear register controllers
  void _clearRegisterControllers() {
    registerNameController.clear();
    registerEmailController.clear();
    registerPasswordController.clear();
    registerConfirmPasswordController.clear();
  }

  @override
  void onClose() {
    loginEmailController.dispose();
    loginPasswordController.dispose();
    registerNameController.dispose();
    registerEmailController.dispose();
    registerPasswordController.dispose();
    registerConfirmPasswordController.dispose();
    super.onClose();
  }
}
