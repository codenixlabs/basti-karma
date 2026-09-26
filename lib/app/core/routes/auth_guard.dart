import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/services/auth_service.dart';
import 'app_pages.dart';

/// Prevents unauthenticated users from accessing protected pages.
class AuthGuard extends GetMiddleware {
  final bool enforceInTest;

  AuthGuard({this.enforceInTest = false});

  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    if (Get.testMode && !enforceInTest) return null;

    final authService =
        Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
    final isAuthenticated = authService?.isAuthenticated ?? false;

    if (!isAuthenticated) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}

/// Prevents already-authenticated users from revisiting guest-only pages
/// (login, register, forgot-password).
class GuestGuard extends GetMiddleware {
  final bool enforceInTest;

  GuestGuard({this.enforceInTest = false});

  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    if (Get.testMode && !enforceInTest) return null;

    final authService =
        Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
    final isAuthenticated = authService?.isAuthenticated ?? false;

    if (isAuthenticated) {
      return const RouteSettings(name: AppRoutes.home);
    }
    return null;
  }
}
