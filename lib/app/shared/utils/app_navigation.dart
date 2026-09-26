import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Safe navigation utility to debounce rapid double-taps and prevent duplicate route pushes.
class AppNavigation {
  static DateTime _lastNavTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _debounceInterval = Duration(milliseconds: 400);

  /// Debounces and navigates to [page], preventing duplicate routes from rapid taps.
  static Future<T?>? toNamed<T>(String page, {dynamic arguments}) {
    final now = DateTime.now();
    if (now.difference(_lastNavTime) < _debounceInterval) {
      return null;
    }
    if (Get.currentRoute == page) {
      return null;
    }
    _lastNavTime = now;
    if (Get.testMode) {
      return Future.value(null);
    }
    return Get.toNamed<T>(page, arguments: arguments);
  }

  /// Safely replaces current route with [page].
  static Future<T?>? offNamed<T>(String page, {dynamic arguments}) {
    final now = DateTime.now();
    if (now.difference(_lastNavTime) < _debounceInterval) {
      return null;
    }
    if (Get.currentRoute == page) {
      return null;
    }
    _lastNavTime = now;
    if (Get.testMode) {
      return Future.value(null);
    }
    return Get.offNamed<T>(page, arguments: arguments);
  }

  /// Safely pops the current screen if canPop is true.
  static void back<T>({T? result}) {
    final context = Get.context;
    if (context != null && Navigator.canPop(context)) {
      Get.back(result: result);
    }
  }

  /// Resets the debounce timestamp for unit testing.
  @visibleForTesting
  static void resetForTesting() {
    _lastNavTime = DateTime.fromMillisecondsSinceEpoch(0);
  }
}
