import 'package:get/get.dart';

import '../models/auth/user_model.dart';
import '../services/api_service.dart';

class AuthResult<T> {
  final bool isSuccess;
  final T? data;
  final String? token;
  final String? refreshToken;
  final String? resetToken;
  final String? message;
  final String? errorMessage;

  const AuthResult.success({
    this.data,
    this.token,
    this.refreshToken,
    this.resetToken,
    this.message,
  })  : isSuccess = true,
        errorMessage = null;

  const AuthResult.failure(this.errorMessage)
      : isSuccess = false,
        data = null,
        token = null,
        refreshToken = null,
        resetToken = null,
        message = null;
}

abstract class IAuthRepository {
  Future<AuthResult<UserModel>> login({
    required String email,
    required String password,
  });

  Future<AuthResult<void>> sendOtp({
    required String email,
  });

  Future<AuthResult<UserModel>> signup({
    required String name,
    required String email,
    required String password,
    required String otp,
    String? role,
  });

  Future<AuthResult<Map<String, String>>> refreshToken({
    required String refreshToken,
  });

  Future<AuthResult<UserModel>> updateProfile({
    String? name,
    String? email,
    String? password,
  });

  Future<AuthResult<void>> forgotPassword({
    required String email,
  });

  Future<AuthResult<String>> verifyResetOtp({
    required String email,
    required String otp,
  });

  Future<AuthResult<void>> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
  });
}

class AuthRepository implements IAuthRepository {
  final ApiService _apiService;

  AuthRepository({ApiService? apiService})
      : _apiService = apiService ??
            (Get.isRegistered<ApiService>()
                ? Get.find<ApiService>()
                : ApiService());

  @override
  Future<AuthResult<UserModel>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        '/auth/login',
        {
          'email': email.trim(),
          'password': password,
        },
      );

      if (response.isOk && response.body is Map) {
        final body = response.body as Map<String, dynamic>;
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          final token = data['token'] as String?;
          final refreshToken = data['refreshToken'] as String?;
          if (token == null || token.isEmpty) {
            return const AuthResult.failure('Authentication token not received.');
          }
          final user = UserModel.fromJson(data);
          return AuthResult.success(
            data: user,
            token: token,
            refreshToken: refreshToken,
            message: body['message']?.toString(),
          );
        }
      }

      final error = ApiService.extractErrorMessage(response);
      return AuthResult.failure(error);
    } catch (e) {
      return AuthResult.failure(ApiService.friendlyExceptionMessage(e));
    }
  }

  @override
  Future<AuthResult<void>> sendOtp({
    required String email,
  }) async {
    try {
      final response = await _apiService.post(
        '/auth/send-otp',
        {
          'email': email.trim(),
        },
      );

      if (response.isOk) {
        String? msg;
        if (response.body is Map) {
          msg = (response.body as Map)['message']?.toString();
        }
        return AuthResult.success(
          message: msg ?? 'OTP sent successfully',
        );
      }

      final error = ApiService.extractErrorMessage(response);
      return AuthResult.failure(error);
    } catch (e) {
      return AuthResult.failure(ApiService.friendlyExceptionMessage(e));
    }
  }

  @override
  Future<AuthResult<UserModel>> signup({
    required String name,
    required String email,
    required String password,
    required String otp,
    String? role,
  }) async {
    try {
      final payload = <String, dynamic>{
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'otp': otp.trim(),
        if (role != null && role.isNotEmpty) 'role': role,
      };

      final response = await _apiService.post('/auth/signup', payload);

      if (response.isOk && response.body is Map) {
        final body = response.body as Map;
        final data = body['data'];
        if (data is Map) {
          final user = UserModel.fromJson(Map<String, dynamic>.from(data));
          return AuthResult.success(
            data: user,
            token: data['token']?.toString(),
            refreshToken: data['refreshToken']?.toString(),
            message: body['message']?.toString(),
          );
        }
        return AuthResult.success(message: body['message']?.toString());
      }

      final error = ApiService.extractErrorMessage(response);
      return AuthResult.failure(error);
    } catch (e) {
      return AuthResult.failure(ApiService.friendlyExceptionMessage(e));
    }
  }

  @override
  Future<AuthResult<Map<String, String>>> refreshToken({
    required String refreshToken,
  }) async {
    try {
      final response = await _apiService.post(
        '/auth/refresh',
        {
          'refreshToken': refreshToken,
        },
      );

      if (response.isOk && response.body is Map) {
        final body = response.body as Map<String, dynamic>;
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          final token = data['token'] as String?;
          final newRefreshToken = data['refreshToken'] as String?;
          if (token != null && newRefreshToken != null) {
            return AuthResult.success(
              data: {
                'token': token,
                'refreshToken': newRefreshToken,
              },
              token: token,
              refreshToken: newRefreshToken,
              message: body['message']?.toString(),
            );
          }
        }
      }

      final error = ApiService.extractErrorMessage(response);
      return AuthResult.failure(error);
    } catch (e) {
      return AuthResult.failure(ApiService.friendlyExceptionMessage(e));
    }
  }

  @override
  Future<AuthResult<UserModel>> updateProfile({
    String? name,
    String? email,
    String? password,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (name != null && name.trim().isNotEmpty) {
        payload['name'] = name.trim();
      }
      if (email != null && email.trim().isNotEmpty) {
        payload['email'] = email.trim();
      }
      if (password != null && password.trim().isNotEmpty) {
        payload['password'] = password;
      }

      if (payload.isEmpty) {
        return const AuthResult.failure('No profile changes provided.');
      }

      final response = await _apiService.put('/auth/profile', payload);

      if (response.isOk && response.body is Map) {
        final body = response.body as Map;
        final data = body['data'];
        if (data is Map) {
          final user = UserModel.fromJson(Map<String, dynamic>.from(data));
          return AuthResult.success(
            data: user,
            message: body['message']?.toString(),
          );
        }
      }

      final error = ApiService.extractErrorMessage(response);
      return AuthResult.failure(error);
    } catch (e) {
      return AuthResult.failure(ApiService.friendlyExceptionMessage(e));
    }
  }

  @override
  Future<AuthResult<void>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await _apiService.post(
        '/auth/forgot-password',
        {
          'email': email.trim(),
        },
      );

      if (response.isOk) {
        String? msg;
        if (response.body is Map) {
          msg = (response.body as Map)['message']?.toString();
        }
        return AuthResult.success(
          message: msg ?? 'Password reset OTP sent successfully',
        );
      }

      final error = ApiService.extractErrorMessage(response);
      return AuthResult.failure(error);
    } catch (e) {
      return AuthResult.failure(ApiService.friendlyExceptionMessage(e));
    }
  }

  @override
  Future<AuthResult<String>> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _apiService.post(
        '/auth/verify-reset-otp',
        {
          'email': email.trim(),
          'otp': otp.trim(),
        },
      );

      if (response.isOk && response.body is Map) {
        final body = response.body as Map<String, dynamic>;
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          final resetToken = data['resetToken'] as String?;
          if (resetToken != null && resetToken.isNotEmpty) {
            return AuthResult.success(
              data: resetToken,
              resetToken: resetToken,
              message: body['message']?.toString(),
            );
          }
        }
      }

      final error = ApiService.extractErrorMessage(response);
      return AuthResult.failure(error);
    } catch (e) {
      return AuthResult.failure(ApiService.friendlyExceptionMessage(e));
    }
  }

  @override
  Future<AuthResult<void>> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.post(
        '/auth/reset-password',
        {
          'email': email.trim(),
          'resetToken': resetToken.trim(),
          'newPassword': newPassword,
        },
      );

      if (response.isOk) {
        String? msg;
        if (response.body is Map) {
          msg = (response.body as Map)['message']?.toString();
        }
        return AuthResult.success(
          message: msg ?? 'Password reset successfully',
        );
      }

      final error = ApiService.extractErrorMessage(response);
      return AuthResult.failure(error);
    } catch (e) {
      return AuthResult.failure(ApiService.friendlyExceptionMessage(e));
    }
  }
}
