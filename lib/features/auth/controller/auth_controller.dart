import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/constants/app_strings.dart';
import '../../../app/core/routes/app_pages.dart';
import '../../../app/data/repositories/auth_repository.dart';
import '../../../app/data/services/api_service.dart';
import '../../../app/data/services/auth_service.dart';
import '../../../app/shared/utils/custom_snackbar.dart';
import '../../../app/shared/utils/form_validators.dart';
import '../../home/controller/home_controller.dart';

class AuthController extends GetxController {
  final IAuthRepository _authRepository;
  final AuthService _authService;

  AuthController({
    IAuthRepository? authRepository,
    AuthService? authService,
  })  : _authRepository = authRepository ??
            (Get.isRegistered<AuthRepository>()
                ? Get.find<AuthRepository>()
                : AuthRepository()),
        _authService = authService ??
            (Get.isRegistered<AuthService>()
                ? Get.find<AuthService>()
                : AuthService());

  // Form keys
  final loginFormKey = GlobalKey<FormState>();
  final registerFormKey = GlobalKey<FormState>();
  final registerOtpFormKey = GlobalKey<FormState>();
  final forgotPasswordFormKey = GlobalKey<FormState>();
  final forgotOtpFormKey = GlobalKey<FormState>();
  final forgotResetFormKey = GlobalKey<FormState>();

  // Login
  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();

  // Register
  final registerNameController = TextEditingController();
  final registerEmailController = TextEditingController();
  final registerPasswordController = TextEditingController();
  final registerConfirmPasswordController = TextEditingController();
  final registerOtpController = TextEditingController();

  // Signup OTP state
  final isRegisterOtpSent = false.obs;
  final registerOtpCountdown = 0.obs;
  Timer? _registerOtpTimer;

  // Forgot password
  final forgotEmailController = TextEditingController();
  final forgotOtpController = TextEditingController();
  final forgotNewPasswordController = TextEditingController();
  final forgotConfirmPasswordController = TextEditingController();

  // Forgot Password flow: 0 = Email, 1 = OTP, 2 = Reset Password
  final forgotStep = 0.obs;
  final forgotOtpCountdown = 0.obs;
  Timer? _forgotOtpTimer;

  /// Memory-only token returned by /auth/verify-reset-otp.
  /// Never persisted to storage or disk.
  final resetToken = ''.obs;

  // Loading state & progressive cold-start feedback
  final isLoading = false.obs;
  final isForgotLoading = false.obs;
  final isProfileUpdating = false.obs;
  final loadingStatus = ''.obs;

  // Password visibility
  final loginPasswordVisible = false.obs;
  final registerPasswordVisible = false.obs;
  final registerConfirmPasswordVisible = false.obs;
  final forgotNewPasswordVisible = false.obs;
  final forgotConfirmPasswordVisible = false.obs;

  void toggleLoginPasswordVisibility() => loginPasswordVisible.toggle();
  void toggleRegisterPasswordVisibility() => registerPasswordVisible.toggle();
  void toggleConfirmPasswordVisibility() =>
      registerConfirmPasswordVisible.toggle();
  void toggleForgotNewPasswordVisibility() =>
      forgotNewPasswordVisible.toggle();
  void toggleForgotConfirmPasswordVisibility() =>
      forgotConfirmPasswordVisible.toggle();

  @override
  void onClose() {
    _registerOtpTimer?.cancel();
    _forgotOtpTimer?.cancel();
    resetToken.value = '';
    super.onClose();
  }

  // ── Login ───────────────────────────────────────────────────────────────────

  Future<void> login() async {
    if (isLoading.value) return;
    if (loginFormKey.currentState != null &&
        !loginFormKey.currentState!.validate()) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    final normalizedEmail =
        FormValidators.normalizeEmail(loginEmailController.text);
    isLoading.value = true;
    loadingStatus.value = 'Signing in...';

    final timer1 = Timer(const Duration(seconds: 3), () {
      if (isLoading.value) {
        loadingStatus.value = 'Connecting to server (waking up cloud host)...';
      }
    });
    final timer2 = Timer(const Duration(seconds: 10), () {
      if (isLoading.value) {
        loadingStatus.value = 'Still connecting, almost ready...';
      }
    });

    try {
      final result = await _authRepository.login(
        email: normalizedEmail,
        password: loginPasswordController.text,
      );

      if (result.isSuccess && result.data != null && result.token != null) {
        await _authService.saveSession(
          token: result.token!,
          user: result.data!,
          refreshToken: result.refreshToken,
        );

        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().doctorName.value = result.data!.name;
          Get.find<HomeController>().currentIndex.value = 0;
        }

        clearFields();
        if (!Get.testMode && Get.key.currentState != null) {
          Get.offAllNamed(AppRoutes.home);
        }
        CustomSnackBar.showSuccess(AppStrings.loginSuccess);
      } else {
        CustomSnackBar.showError(result.errorMessage ?? AppStrings.loginFailed);
      }
    } catch (e) {
      CustomSnackBar.showError('${AppStrings.loginFailed}: $e');
    } finally {
      timer1.cancel();
      timer2.cancel();
      loadingStatus.value = '';
      isLoading.value = false;
    }
  }

  // ── Signup with OTP ─────────────────────────────────────────────────────────

  /// Step 1: Validate initial registration info and send OTP.
  Future<void> startSignupFlow() async {
    if (isLoading.value) return;
    if (registerFormKey.currentState != null &&
        !registerFormKey.currentState!.validate()) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    final normalizedEmail =
        FormValidators.normalizeEmail(registerEmailController.text);
    isLoading.value = true;
    loadingStatus.value = 'Sending verification code...';

    try {
      final result = await _authRepository.sendOtp(email: normalizedEmail);

      if (result.isSuccess) {
        isRegisterOtpSent.value = true;
        _startRegisterCountdown();
        CustomSnackBar.showSuccess(
          result.message ?? 'Verification OTP sent to $normalizedEmail',
        );
      } else {
        CustomSnackBar.showError(
          result.errorMessage ?? 'Failed to send verification OTP.',
        );
      }
    } catch (e) {
      CustomSnackBar.showError('Error sending OTP: $e');
    } finally {
      loadingStatus.value = '';
      isLoading.value = false;
    }
  }

  void _startRegisterCountdown() {
    _registerOtpTimer?.cancel();
    registerOtpCountdown.value = 60;
    _registerOtpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (registerOtpCountdown.value > 0) {
        registerOtpCountdown.value--;
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> resendSignupOtp() async {
    if (isLoading.value || registerOtpCountdown.value > 0) return;

    final normalizedEmail =
        FormValidators.normalizeEmail(registerEmailController.text);
    isLoading.value = true;
    loadingStatus.value = 'Resending code...';

    try {
      final result = await _authRepository.sendOtp(email: normalizedEmail);
      if (result.isSuccess) {
        _startRegisterCountdown();
        CustomSnackBar.showSuccess(
          result.message ?? 'Verification OTP resent to $normalizedEmail',
        );
      } else {
        CustomSnackBar.showError(
          result.errorMessage ?? 'Failed to resend verification OTP.',
        );
      }
    } catch (e) {
      CustomSnackBar.showError('Error resending OTP: $e');
    } finally {
      loadingStatus.value = '';
      isLoading.value = false;
    }
  }

  /// Step 2: Submit registration with OTP to create user account.
  Future<void> completeSignup() async {
    if (isLoading.value) return;

    final otp = registerOtpController.text.trim();
    if (otp.length != 6) {
      CustomSnackBar.showError('Please enter a valid 6-digit OTP');
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    final normalizedEmail =
        FormValidators.normalizeEmail(registerEmailController.text);
    isLoading.value = true;
    loadingStatus.value = 'Creating account...';

    try {
      final result = await _authRepository.signup(
        name: registerNameController.text.trim(),
        email: normalizedEmail,
        password: registerPasswordController.text,
        otp: otp,
        role: 'doctor',
      );

      if (result.isSuccess) {
        loginEmailController.text = normalizedEmail;
        cancelRegisterOtp();
        registerPasswordController.clear();
        registerConfirmPasswordController.clear();

        if (!Get.testMode && Get.key.currentState != null) {
          if (Get.previousRoute == AppRoutes.login) {
            Get.back();
          } else {
            Get.offNamed(AppRoutes.login);
          }
        }
        CustomSnackBar.showSuccess(
          result.message ?? AppStrings.registerSuccessMessage,
        );
      } else {
        CustomSnackBar.showError(
          result.errorMessage ?? AppStrings.registrationFailed,
        );
      }
    } catch (e) {
      CustomSnackBar.showError('${AppStrings.registrationFailed}: $e');
    } finally {
      loadingStatus.value = '';
      isLoading.value = false;
    }
  }

  void cancelRegisterOtp() {
    isRegisterOtpSent.value = false;
    registerOtpController.clear();
    _registerOtpTimer?.cancel();
    registerOtpCountdown.value = 0;
  }

  /// Preserved for backwards compatibility with test calls.
  Future<void> register() async {
    if (isRegisterOtpSent.value) {
      await completeSignup();
    } else {
      await startSignupFlow();
    }
  }

  // ── Forgot Password (3-Step Flow) ──────────────────────────────────────────

  /// Step 1: Send OTP to email.
  Future<void> sendForgotPasswordOtp() async {
    if (isForgotLoading.value) return;
    if (forgotPasswordFormKey.currentState != null &&
        !forgotPasswordFormKey.currentState!.validate()) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    final normalizedEmail =
        FormValidators.normalizeEmail(forgotEmailController.text);
    isForgotLoading.value = true;

    try {
      final result =
          await _authRepository.forgotPassword(email: normalizedEmail);

      if (result.isSuccess) {
        forgotStep.value = 1;
        _startForgotCountdown();
        CustomSnackBar.showSuccess(
          result.message ?? 'Password reset OTP sent to $normalizedEmail',
        );
      } else {
        CustomSnackBar.showError(
          result.errorMessage ?? 'Failed to send password reset OTP.',
        );
      }
    } catch (e) {
      CustomSnackBar.showError(ApiService.friendlyExceptionMessage(e));
    } finally {
      isForgotLoading.value = false;
    }
  }

  void _startForgotCountdown() {
    _forgotOtpTimer?.cancel();
    forgotOtpCountdown.value = 60;
    _forgotOtpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (forgotOtpCountdown.value > 0) {
        forgotOtpCountdown.value--;
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> resendForgotOtp() async {
    if (isForgotLoading.value || forgotOtpCountdown.value > 0) return;

    final normalizedEmail =
        FormValidators.normalizeEmail(forgotEmailController.text);
    isForgotLoading.value = true;

    try {
      final result =
          await _authRepository.forgotPassword(email: normalizedEmail);
      if (result.isSuccess) {
        _startForgotCountdown();
        CustomSnackBar.showSuccess(
          result.message ?? 'Password reset OTP resent to $normalizedEmail',
        );
      } else {
        CustomSnackBar.showError(
          result.errorMessage ?? 'Failed to resend reset OTP.',
        );
      }
    } catch (e) {
      CustomSnackBar.showError(ApiService.friendlyExceptionMessage(e));
    } finally {
      isForgotLoading.value = false;
    }
  }

  /// Step 2: Verify reset OTP and retrieve memory-only resetToken.
  Future<void> verifyForgotOtp() async {
    if (isForgotLoading.value) return;

    final otp = forgotOtpController.text.trim();
    if (otp.length != 6) {
      CustomSnackBar.showError('Please enter a valid 6-digit OTP');
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    final normalizedEmail =
        FormValidators.normalizeEmail(forgotEmailController.text);
    isForgotLoading.value = true;

    try {
      final result = await _authRepository.verifyResetOtp(
        email: normalizedEmail,
        otp: otp,
      );

      if (result.isSuccess && result.resetToken != null) {
        resetToken.value = result.resetToken!;
        forgotStep.value = 2;
        CustomSnackBar.showSuccess(
          result.message ?? 'OTP verified. Please enter your new password.',
        );
      } else {
        CustomSnackBar.showError(
          result.errorMessage ?? 'Invalid or expired OTP.',
        );
      }
    } catch (e) {
      CustomSnackBar.showError(ApiService.friendlyExceptionMessage(e));
    } finally {
      isForgotLoading.value = false;
    }
  }

  /// Step 3: Submit new password with memory-only resetToken.
  Future<void> submitResetPassword() async {
    if (isForgotLoading.value) return;
    if (forgotResetFormKey.currentState != null &&
        !forgotResetFormKey.currentState!.validate()) {
      return;
    }

    if (resetToken.value.isEmpty) {
      CustomSnackBar.showError('Session expired. Please restart the reset process.');
      resetForgotPasswordFlow();
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    final normalizedEmail =
        FormValidators.normalizeEmail(forgotEmailController.text);
    isForgotLoading.value = true;

    try {
      final result = await _authRepository.resetPassword(
        email: normalizedEmail,
        resetToken: resetToken.value,
        newPassword: forgotNewPasswordController.text,
      );

      if (result.isSuccess) {
        resetForgotPasswordFlow();
        if (!Get.testMode && Get.key.currentState != null) {
          Get.offNamed(AppRoutes.login);
        }
        CustomSnackBar.showSuccess(
          result.message ?? 'Password reset successfully. Please log in.',
        );
      } else {
        CustomSnackBar.showError(
          result.errorMessage ?? 'Failed to reset password.',
        );
      }
    } catch (e) {
      CustomSnackBar.showError(ApiService.friendlyExceptionMessage(e));
    } finally {
      isForgotLoading.value = false;
    }
  }

  void resetForgotPasswordFlow() {
    forgotStep.value = 0;
    resetToken.value = '';
    _forgotOtpTimer?.cancel();
    forgotOtpCountdown.value = 0;
    forgotEmailController.clear();
    forgotOtpController.clear();
    forgotNewPasswordController.clear();
    forgotConfirmPasswordController.clear();
  }

  /// Backward-compatibility delegate
  Future<void> forgotPassword() async {
    if (forgotStep.value == 0) {
      await sendForgotPasswordOtp();
    } else if (forgotStep.value == 1) {
      await verifyForgotOtp();
    } else {
      await submitResetPassword();
    }
  }

  // ── Profile Update ──────────────────────────────────────────────────────────

  Future<bool> updateProfile({
    required String name,
    required String email,
    String? password,
  }) async {
    if (isProfileUpdating.value) return false;

    final trimmedName = name.trim();
    final trimmedEmail = FormValidators.normalizeEmail(email);
    final trimmedPassword =
        password != null && password.trim().isNotEmpty ? password.trim() : null;

    final currentUser = _authService.currentUser.value;
    final nameChanged =
        trimmedName.isNotEmpty && trimmedName != currentUser?.name;
    final emailChanged =
        trimmedEmail.isNotEmpty && trimmedEmail != currentUser?.email;
    final passwordProvided = trimmedPassword != null;

    if (!nameChanged && !emailChanged && !passwordProvided) {
      CustomSnackBar.showInfo('No changes to update.');
      return false;
    }

    isProfileUpdating.value = true;
    try {
      final result = await _authRepository.updateProfile(
        name: nameChanged ? trimmedName : null,
        email: emailChanged ? trimmedEmail : null,
        password: passwordProvided ? trimmedPassword : null,
      );

      if (result.isSuccess && result.data != null) {
        await _authService.updateUser(result.data!);
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().doctorName.value = result.data!.name;
        }
        CustomSnackBar.showSuccess(
          result.message ?? 'Profile updated successfully',
        );
        return true;
      } else {
        CustomSnackBar.showError(
          result.errorMessage ?? 'Failed to update profile',
        );
        return false;
      }
    } catch (e) {
      CustomSnackBar.showError('Profile update failed: $e');
      return false;
    } finally {
      isProfileUpdating.value = false;
    }
  }

  // ── Session & Cleanup ───────────────────────────────────────────────────────

  Future<void> logout() async {
    clearFields();
    await _authService.logout();
  }

  void clearFields() {
    loginEmailController.clear();
    loginPasswordController.clear();
    registerNameController.clear();
    registerEmailController.clear();
    registerPasswordController.clear();
    registerConfirmPasswordController.clear();
    registerOtpController.clear();
    forgotEmailController.clear();
    forgotOtpController.clear();
    forgotNewPasswordController.clear();
    forgotConfirmPasswordController.clear();
    cancelRegisterOtp();
    resetForgotPasswordFlow();
    resetToken.value = '';
    loadingStatus.value = '';
    isLoading.value = false;
    isForgotLoading.value = false;
    isProfileUpdating.value = false;
    loginPasswordVisible.value = false;
    registerPasswordVisible.value = false;
    registerConfirmPasswordVisible.value = false;
    forgotNewPasswordVisible.value = false;
    forgotConfirmPasswordVisible.value = false;
  }
}
