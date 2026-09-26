import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/routes/app_pages.dart';
import '../models/auth/user_model.dart';
import '../../../features/assessment/controller/assessment_controller.dart';
import '../../../features/assessment/controller/treatment_plan_controller.dart';
import '../../../features/auth/controller/auth_controller.dart';
import '../../../features/home/controller/home_controller.dart';
import '../../../features/patients/controller/add_patient_controller.dart';
import '../../../features/patients/controller/patient_controller.dart';
import '../../../features/profile/controller/profile_controller.dart';

class AuthService extends GetxService {
  static const String _keyToken = 'auth_jwt_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  static const String _keyUser = 'auth_user_data';

  SharedPreferences? _prefs;

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxString token = ''.obs;
  final RxString refreshToken = ''.obs;
  final RxBool isLoggedIn = false.obs;

  /// Decodes the payload portion of a JWT without exposing secrets.
  /// Returns null if token is malformed.
  static Map<String, dynamic>? decodeTokenPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(payloadString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Checks whether a JWT token is expired based on its `exp` claim.
  /// An optional [buffer] protects against clock skew and network latency.
  /// Returns false if the token cannot be parsed as a JWT (relying on backend 401).
  static bool isTokenExpired(String? token, {Duration buffer = Duration.zero}) {
    if (token == null || token.trim().isEmpty) return true;
    final payload = decodeTokenPayload(token);
    if (payload == null) {
      // If the token is not a 3-part JWT (e.g. opaque token or test mock),
      // we cannot determine expiry locally. Defer to backend 401.
      return false;
    }
    final exp = payload['exp'];
    if (exp is int) {
      final expDateTime =
          DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
      final compareTime = DateTime.now().toUtc().add(buffer);
      return compareTime.isAfter(expDateTime);
    }
    return false;
  }

  bool get isAuthenticated =>
      isLoggedIn.value && token.value.isNotEmpty && !isTokenExpired(token.value);
  String? get currentToken => token.value.isEmpty ? null : token.value;
  String? get currentRefreshToken =>
      refreshToken.value.isEmpty ? null : refreshToken.value;

  Future<AuthService> init({SharedPreferences? prefs}) async {
    _prefs = prefs ?? await SharedPreferences.getInstance();

    final savedToken = _prefs?.getString(_keyToken);
    final savedRefreshToken = _prefs?.getString(_keyRefreshToken);
    final savedUserJson = _prefs?.getString(_keyUser);

    if (savedToken != null && savedToken.isNotEmpty) {
      if (isTokenExpired(savedToken)) {
        // If access token is expired, but we have a valid refresh token,
        // retain session so ApiService can refresh on next API request.
        if (savedRefreshToken != null &&
            savedRefreshToken.isNotEmpty &&
            !isTokenExpired(savedRefreshToken)) {
          token.value = savedToken;
          refreshToken.value = savedRefreshToken;
          if (savedUserJson != null && savedUserJson.isNotEmpty) {
            try {
              final Map<String, dynamic> userMap = jsonDecode(savedUserJson);
              currentUser.value = UserModel.fromJson(userMap);
            } catch (_) {
              currentUser.value = null;
            }
          }
          isLoggedIn.value = true;
          return this;
        }

        // Stored token has expired and no valid refresh token. Clear stale session.
        await clearSession();
        return this;
      }

      token.value = savedToken;
      refreshToken.value = savedRefreshToken ?? '';
      if (savedUserJson != null && savedUserJson.isNotEmpty) {
        try {
          final Map<String, dynamic> userMap = jsonDecode(savedUserJson);
          currentUser.value = UserModel.fromJson(userMap);
        } catch (_) {
          currentUser.value = null;
        }
      }
      isLoggedIn.value = true;
    } else {
      token.value = '';
      refreshToken.value = '';
      currentUser.value = null;
      isLoggedIn.value = false;
    }

    return this;
  }

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> saveSession({
    required String token,
    required UserModel user,
    String? refreshToken,
  }) async {
    this.token.value = token;
    if (refreshToken != null) {
      this.refreshToken.value = refreshToken;
    }
    currentUser.value = user;
    isLoggedIn.value = true;

    final prefs = await _getPrefs();
    await prefs.setString(_keyToken, token);
    if (refreshToken != null) {
      await prefs.setString(_keyRefreshToken, refreshToken);
    }
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  /// Updates access and refresh tokens without modifying the user profile.
  Future<void> updateTokens({
    required String token,
    required String refreshToken,
  }) async {
    this.token.value = token;
    this.refreshToken.value = refreshToken;

    final prefs = await _getPrefs();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyRefreshToken, refreshToken);
  }

  /// Updates the current user profile in memory and in storage.
  Future<void> updateUser(UserModel user) async {
    currentUser.value = user;
    final prefs = await _getPrefs();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  Future<void> clearSession() async {
    token.value = '';
    refreshToken.value = '';
    currentUser.value = null;
    isLoggedIn.value = false;

    final prefs = await _getPrefs();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUser);

    // 1. Reset all AuthController text fields and states
    if (Get.isRegistered<AuthController>()) {
      Get.find<AuthController>().clearFields();
    }

    // 2. Clear & dispose PatientController to prevent cross-account patient data leakage
    if (Get.isRegistered<PatientController>()) {
      final patientCtrl = Get.find<PatientController>();
      patientCtrl.clearData();
      Get.delete<PatientController>(force: true);
    }

    // 3. Clear & dispose HomeController to reset tab index to 0 and stats
    if (Get.isRegistered<HomeController>()) {
      final homeCtrl = Get.find<HomeController>();
      homeCtrl.resetState();
      Get.delete<HomeController>(force: true);
    }

    // 4. Clear & dispose TreatmentPlanController
    if (Get.isRegistered<TreatmentPlanController>()) {
      final tpCtrl = Get.find<TreatmentPlanController>();
      tpCtrl.clearData();
      Get.delete<TreatmentPlanController>(force: true);
    }

    // 5. Dispose ProfileController so old user's profile info is not kept in form fields
    if (Get.isRegistered<ProfileController>()) {
      Get.delete<ProfileController>(force: true);
    }

    // 6. Dispose other workflow controllers if registered
    if (Get.isRegistered<AddPatientController>()) {
      Get.delete<AddPatientController>(force: true);
    }
    if (Get.isRegistered<AssessmentController>()) {
      Get.delete<AssessmentController>(force: true);
    }
  }

  Future<void> logout() async {
    await clearSession();
    if (!Get.testMode &&
        Get.key.currentState != null &&
        Get.currentRoute != AppRoutes.login) {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  void handleUnauthorized() {
    if (isLoggedIn.value) {
      clearSession();
      if (!Get.testMode &&
          Get.key.currentState != null &&
          Get.currentRoute != AppRoutes.login) {
        Get.offAllNamed(AppRoutes.login);
      }
    }
  }
}
