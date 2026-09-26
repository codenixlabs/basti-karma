import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/core/theme/app_theme.dart';
import '../../../app/data/models/auth/user_model.dart';
import '../../../app/data/repositories/auth_repository.dart';
import '../../../app/data/services/auth_service.dart';
import '../../../app/shared/utils/custom_snackbar.dart';
import '../../../app/shared/widgets/app_dialog.dart';
import '../../home/controller/home_controller.dart';

class ProfileController extends GetxController {
  final AuthService _authService;
  final AuthRepository _authRepository;

  ProfileController({
    AuthService? authService,
    AuthRepository? authRepository,
  })  : _authService = authService ??
            (Get.isRegistered<AuthService>()
                ? Get.find<AuthService>()
                : Get.put(AuthService())),
        _authRepository = authRepository ??
            (Get.isRegistered<AuthRepository>()
                ? Get.find<AuthRepository>()
                : Get.put(AuthRepository()));

  // ── Observables ────────────────────────────────────────────────────────────
  Rx<UserModel?> get currentUser => _authService.currentUser;

  final isSavingProfile = false.obs;
  final profileErrorMessage = RxnString();

  final isSavingPassword = false.obs;
  final passwordErrorMessage = RxnString();
  final isNewPasswordObscured = true.obs;
  final isConfirmPasswordObscured = true.obs;

  final isLoggingOut = false.obs;

  // ── Form Controllers ───────────────────────────────────────────────────────
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController newPasswordController;
  late final TextEditingController confirmPasswordController;

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController(text: currentUser.value?.name ?? '');
    emailController =
        TextEditingController(text: currentUser.value?.email ?? '');
    newPasswordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  // ── Initials Generation ────────────────────────────────────────────────────
  /// Generates a clean, professional 1-2 letter monogram for avatars.
  /// Handles "Dr.", "Dr ", multiple names, single names, and null/empty states.
  String getInitials([String? rawName]) {
    final name = (rawName ?? currentUser.value?.name ?? '').trim();
    if (name.isEmpty) return 'DR';

    // Remove common title prefixes for initials generation
    var clean = name;
    final prefixes = ['dr.', 'dr ', 'doctor '];
    for (final prefix in prefixes) {
      if (clean.toLowerCase().startsWith(prefix)) {
        clean = clean.substring(prefix.length).trim();
        break;
      }
    }

    if (clean.isEmpty) return 'DR';

    final parts = clean
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      final first = parts[0][0].toUpperCase();
      final second = parts[1][0].toUpperCase();
      return '$first$second';
    } else if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'DR';
  }

  // ── Edit Profile ───────────────────────────────────────────────────────────
  void resetEditProfileForm() {
    nameController.text = currentUser.value?.name ?? '';
    emailController.text = currentUser.value?.email ?? '';
    profileErrorMessage.value = null;
  }

  /// Validates and submits profile changes.
  /// Sends ONLY changed practitioner name to `PUT /api/auth/profile`.
  /// Email is non-editable and cannot be updated.
  Future<bool> saveProfile() async {
    if (isSavingProfile.value) return false;

    FocusManager.instance.primaryFocus?.unfocus();
    profileErrorMessage.value = null;

    final trimmedName = nameController.text.trim();

    if (trimmedName.isEmpty) {
      profileErrorMessage.value = 'Name cannot be empty';
      CustomSnackBar.showError('Please enter your full name');
      return false;
    }

    final user = currentUser.value;
    final nameChanged = trimmedName != (user?.name ?? '');

    if (!nameChanged) {
      CustomSnackBar.showInfo('No changes to update.');
      return false;
    }

    isSavingProfile.value = true;
    try {
      final result = await _authRepository.updateProfile(
        name: trimmedName,
      );

      if (result.isSuccess && result.data != null) {
        await _authService.updateUser(result.data!);

        // Synchronize home doctor name display
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().doctorName.value = result.data!.name;
        }

        CustomSnackBar.showSuccess(
          result.message ?? 'Profile updated successfully',
        );
        return true;
      } else {
        final error = result.errorMessage ?? 'Failed to update profile';
        profileErrorMessage.value = error;
        CustomSnackBar.showError(error);
        return false;
      }
    } catch (e) {
      final error = 'Profile update failed: $e';
      profileErrorMessage.value = error;
      CustomSnackBar.showError(error);
      return false;
    } finally {
      isSavingProfile.value = false;
    }
  }

  // ── Change Password ────────────────────────────────────────────────────────
  void resetChangePasswordForm() {
    newPasswordController.clear();
    confirmPasswordController.clear();
    isNewPasswordObscured.value = true;
    isConfirmPasswordObscured.value = true;
    passwordErrorMessage.value = null;
  }

  void toggleNewPasswordVisibility() {
    isNewPasswordObscured.value = !isNewPasswordObscured.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordObscured.value = !isConfirmPasswordObscured.value;
  }

  /// Validates and submits new password to `PUT /api/auth/profile`.
  /// Password is never logged, never stored locally.
  Future<bool> changePassword() async {
    if (isSavingPassword.value) return false;

    FocusManager.instance.primaryFocus?.unfocus();
    passwordErrorMessage.value = null;

    final newPass = newPasswordController.text;
    final confirmPass = confirmPasswordController.text;

    if (newPass.length < 6) {
      const error = 'Password must be at least 6 characters';
      passwordErrorMessage.value = error;
      CustomSnackBar.showError(error);
      return false;
    }

    if (newPass != confirmPass) {
      const error = 'Passwords do not match';
      passwordErrorMessage.value = error;
      CustomSnackBar.showError(error);
      return false;
    }

    isSavingPassword.value = true;
    try {
      final result = await _authRepository.updateProfile(
        password: newPass,
      );

      if (result.isSuccess) {
        resetChangePasswordForm();
        CustomSnackBar.showSuccess(
          result.message ?? 'Password changed successfully',
        );
        return true;
      } else {
        final error = result.errorMessage ?? 'Failed to update password';
        passwordErrorMessage.value = error;
        CustomSnackBar.showError(error);
        return false;
      }
    } catch (e) {
      final error = 'Password update failed: $e';
      passwordErrorMessage.value = error;
      CustomSnackBar.showError(error);
      return false;
    } finally {
      isSavingPassword.value = false;
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> confirmLogout(BuildContext context) async {
    if (isLoggingOut.value) return;
    if (Get.isDialogOpen ?? false) return;

    final confirmed = await AppDialog.showConfirmation(
      icon: Icons.logout_rounded,
      iconColor: AppColors.errorRed,
      title: 'Log out of BastiKarma?',
      content:
          'Your active clinical session will be securely ended. You can sign back in at any time.',
      cancelText: 'Cancel',
      confirmText: 'Log Out',
      confirmColor: AppColors.errorRed,
      barrierDismissible: true,
    );

    if (confirmed == true) {
      isLoggingOut.value = true;
      try {
        await _authService.logout();
        CustomSnackBar.showInfo('Logged out successfully');
      } catch (e) {
        if (!isClosed) {
          isLoggingOut.value = false;
        }
      }
    }
  }
}
