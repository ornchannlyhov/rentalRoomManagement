import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:joul_v2/data/dtos/user_dto.dart';
import 'package:joul_v2/data/models/user.dart';

class StorageKeys {
  static const token = 'auth_token';
  static const user = 'user';
  static const tokenExpiry = 'token_expiry';
}

class RequestRegistrationRequest {
  final String phoneNumber;
  final String username;
  final String password;
  final String confirmPassword;

  RequestRegistrationRequest({
    required this.phoneNumber,
    required this.username,
    required this.password,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'username': username,
        'password': password,
        'confirmPassword': confirmPassword,
      };
}

class VerifyRegistrationRequest {
  final String phoneNumber;
  final String otp;
  final String username;
  final String password;

  VerifyRegistrationRequest({
    required this.phoneNumber,
    required this.otp,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'otp': otp,
        'username': username,
        'password': password,
      };
}

class LoginRequest {
  final String identifier;
  final String password;

  LoginRequest({
    required this.identifier,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'identifier': identifier,
        'password': password,
      };
}

class RequestPasswordResetRequest {
  final String phoneNumber;

  RequestPasswordResetRequest({required this.phoneNumber});

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
      };
}

class VerifyPasswordResetRequest {
  final String phoneNumber;
  final String otp;
  final String newPassword;
  final String confirmPassword;

  VerifyPasswordResetRequest({
    required this.phoneNumber,
    required this.otp,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'otp': otp,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      };
}

class ResendOtpRequest {
  final String phoneNumber;
  final String purpose;

  ResendOtpRequest({
    required this.phoneNumber,
    required this.purpose,
  });

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'purpose': purpose,
      };
}

class UpdatePasswordRequest {
  final String oldPassword;
  final String newPassword;
  final String? confirmPassword;

  UpdatePasswordRequest({
    required this.oldPassword,
    required this.newPassword,
    this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    final data = {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    };
    if (confirmPassword != null) {
      data['confirmPassword'] = confirmPassword!;
    }
    return data;
  }
}

class UpdateFCMTokenRequest {
  final String fcmToken;

  UpdateFCMTokenRequest({required this.fcmToken});

  Map<String, dynamic> toJson() => {
        'fcmToken': fcmToken,
      };
}

class AuthRepository {
  final ApiHelper _apiHelper = ApiHelper.instance;
  final Logger _logger = Logger();

  Future<bool> _hasNetwork() => _apiHelper.hasNetwork();

  /// Validate token and get user profile
  Future<UserDto?> _validateTokenAndGetUser() async {
    final token = await _apiHelper.storage.read(key: StorageKeys.token);
    if (token == null || token.isEmpty) return null;

    // Check token expiry first (offline-capable)
    if (await _isTokenExpired()) {
      _logger.w('Token expired, clearing auth');
      await _clearAuth();
      return null;
    }

    // If online, validate with server
    if (await _hasNetwork()) {
      try {
        final response = await _apiHelper.dio.get(
          '${_apiHelper.baseUrl}/auth/profile',
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
            validateStatus: (status) => status! < 500,
          ),
        );

        if (response.statusCode == 200 && response.data['success'] == true) {
          final userDto = UserDto.fromJson(response.data['user']);
          await _apiHelper.storage.write(
            key: StorageKeys.user,
            value: jsonEncode(userDto.toJson()),
          );

          // Update token expiry
          await _updateTokenExpiry();

          return userDto;
        } else if (response.statusCode == 401) {
          await _clearAuth();
          return null;
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          await _clearAuth();
          return null;
        }
        _logger.e("Token validation failed: ${e.message}");
        // On network error, fall back to cached user if token not expired
        if (!await _isTokenExpired()) {
          final userJson = await _apiHelper.storage.read(key: StorageKeys.user);
          if (userJson != null && userJson.isNotEmpty) {
            return UserDto.fromJson(jsonDecode(userJson));
          }
        }
        return null;
      } catch (e) {
        _logger.e("Unexpected error during token validation: $e");
        return null;
      }
    } else {
      // Offline - use cached user if token not expired
      final userJson = await _apiHelper.storage.read(key: StorageKeys.user);
      if (userJson != null && userJson.isNotEmpty) {
        try {
          return UserDto.fromJson(jsonDecode(userJson));
        } catch (e) {
          _logger.e("Failed to parse cached user: $e");
          return null;
        }
      }
    }

    return null;
  }

  /// Check if token is expired based on stored expiry time
  Future<bool> _isTokenExpired() async {
    final expiryStr =
        await _apiHelper.storage.read(key: StorageKeys.tokenExpiry);
    if (expiryStr == null) return false;

    try {
      final expiry = DateTime.parse(expiryStr);
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      _logger.e("Failed to parse token expiry: $e");
      return false;
    }
  }

  /// Update token expiry (typically 24 hours from now)
  Future<void> _updateTokenExpiry() async {
    final expiry = DateTime.now().add(const Duration(hours: 24));
    await _apiHelper.storage.write(
      key: StorageKeys.tokenExpiry,
      value: expiry.toIso8601String(),
    );
  }

  /// Clear authentication data
  Future<void> _clearAuth() async {
    await _apiHelper.storage.delete(key: StorageKeys.token);
    await _apiHelper.storage.delete(key: StorageKeys.user);
    await _apiHelper.storage.delete(key: StorageKeys.tokenExpiry);
  }

  // --- Registration Flow ---

  /// Request registration with password (OTP sent to phone)
  Future<void> requestRegistration(RequestRegistrationRequest request) async {
    if (!await _hasNetwork()) {
      throw Exception("No internet connection.");
    }

    final url = '${_apiHelper.baseUrl}/auth/register';

    try {
      final response = await _apiHelper.dio.post(url, data: request.toJson());

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] == true) {
        _logger.i('OTP sent successfully for registration');
      } else {
        throw Exception(
            response.data['message'] ?? 'Failed to request registration');
      }
    } on DioException catch (e) {
      _handleDioError(e, 'Registration request failed');
    }
  }

  /// Verify OTP and create account with password
  Future<User> verifyRegistration(VerifyRegistrationRequest request) async {
    if (!await _hasNetwork()) {
      throw Exception("No internet connection.");
    }

    final url = '${_apiHelper.baseUrl}/auth/register/verify';

    try {
      _logger.i(
          'Verifying registration for ${request.phoneNumber} with OTP ${request.otp}');
      final response = await _apiHelper.dio.post(url, data: request.toJson());
      _logger.d(
          'Verify Registration Response: ${response.statusCode} - ${response.data}');

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] == true) {
        return await _handleAuthResponse(response.data);
      } else {
        final message = response.data['message'] ?? 'Verification failed';
        _logger.w('Verification failed: $message');
        throw Exception(message);
      }
    } on DioException catch (e) {
      _logger.e(
          'DioException during verify registration: ${e.message} - ${e.response?.data}');
      _handleDioError(e, 'Verification failed');
      throw Exception('Unreachable'); // Should be handled by _handleDioError
    }
  }

  // --- Login Flow ---

  /// Login with username/phone and password
  Future<User> login(LoginRequest request) async {
    if (!await _hasNetwork()) {
      throw Exception("No internet connection.");
    }

    final url = '${_apiHelper.baseUrl}/auth/login';

    try {
      _logger.i('Attempting login for ${request.identifier}');
      final response = await _apiHelper.dio.post(url, data: request.toJson());
      _logger.d('Login Response: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return await _handleAuthResponse(response.data);
      } else {
        final message = response.data['message'] ?? 'Login failed';
        _logger.w('Login failed: $message');
        throw Exception(message);
      }
    } on DioException catch (e) {
      _logger
          .e('DioException during login: ${e.message} - ${e.response?.data}');
      _handleDioError(e, 'Login failed');
      throw Exception('Unreachable');
    }
  }

  // --- Password Reset Flow ---

  /// Request password reset OTP
  Future<void> requestPasswordReset(RequestPasswordResetRequest request) async {
    if (!await _hasNetwork()) {
      throw Exception("No internet connection.");
    }

    final url = '${_apiHelper.baseUrl}/auth/password/reset';

    try {
      final response = await _apiHelper.dio.post(url, data: request.toJson());

      if (response.statusCode == 200 && response.data['success'] == true) {
        _logger.i('Password reset OTP sent successfully');
      } else {
        throw Exception(response.data['message'] ?? 'Failed to send reset OTP');
      }
    } on DioException catch (e) {
      _handleDioError(e, 'Password reset request failed');
    }
  }

  /// Verify OTP and reset password
  Future<void> verifyPasswordReset(VerifyPasswordResetRequest request) async {
    if (!await _hasNetwork()) {
      throw Exception("No internet connection.");
    }

    final url = '${_apiHelper.baseUrl}/auth/password/reset/verify';

    try {
      final response = await _apiHelper.dio.post(url, data: request.toJson());

      if (response.statusCode == 200 && response.data['success'] == true) {
        _logger.i('Password reset successfully');
      } else {
        throw Exception(response.data['message'] ?? 'Password reset failed');
      }
    } on DioException catch (e) {
      _handleDioError(e, 'Password reset verification failed');
    }
  }

  /// Resend OTP with purpose
  Future<void> resendOtp(ResendOtpRequest request) async {
    if (!await _hasNetwork()) {
      throw Exception("No internet connection.");
    }

    final url = '${_apiHelper.baseUrl}/auth/otp/resend';

    try {
      final response = await _apiHelper.dio.post(url, data: request.toJson());

      if (response.statusCode == 200 && response.data['success'] == true) {
        _logger.i('OTP resent successfully');
      } else {
        throw Exception(response.data['message'] ?? 'Failed to resend OTP');
      }
    } on DioException catch (e) {
      _handleDioError(e, 'Resend OTP failed');
    }
  }

  // --- Helper Methods ---

  Future<User> _handleAuthResponse(Map<String, dynamic> data) async {
    _logger.d('Auth Response Data: $data');

    if (data['token'] == null) {
      throw Exception(
          'Authentication failed: Token missing in server response');
    }
    if (data['user'] == null) {
      throw Exception(
          'Authentication failed: User data missing in server response');
    }

    final token = data['token'] as String;
    final userDto = UserDto.fromJson(data['user']);

    await _apiHelper.storage.write(key: StorageKeys.token, value: token);
    await _apiHelper.storage.write(
      key: StorageKeys.user,
      value: jsonEncode(userDto.toJson()),
    );
    await _updateTokenExpiry();

    _logger.i('User authenticated successfully');
    return User(
      id: userDto.id,
      username: userDto.username,
      phoneNumber: userDto.phoneNumber,
      phoneVerified: userDto.phoneVerified,
      email: userDto.email,
      fcmToken: userDto.fcmToken,
      token: token,
    );
  }

  void _handleDioError(DioException e, String defaultMessage) {
    _logger.e('$defaultMessage: ${e.message}');
    final errorMessage = e.response?.data['message'] ??
        e.response?.data['error'] ??
        e.message ??
        defaultMessage;
    throw Exception(errorMessage);
  }

  /// Update password (requires network)
  Future<void> updatePassword(UpdatePasswordRequest request) async {
    if (!await _hasNetwork()) {
      throw Exception(
          "No internet connection. Password update requires network access.");
    }

    final token = await _apiHelper.storage.read(key: StorageKeys.token);
    if (token == null || token.isEmpty) {
      throw Exception("Not authenticated.");
    }

    final url = '${_apiHelper.baseUrl}/auth/password/update';

    try {
      _logger.i('Updating password at $url with data: ${request.toJson()}');
      final response = await _apiHelper.dio.put(
        url,
        data: request.toJson(),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        _logger.i('Password updated successfully');
      } else {
        final error = response.data['message'] ?? 'Password update failed';
        throw Exception(error);
      }
    } on DioException catch (e) {
      final message = e.response?.data['message'] ??
          e.response?.data['error'] ??
          e.message ??
          'Failed to update password';
      _logger.e("Update password failed: $message");
      throw Exception(message);
    }
  }

  /// Logout user (works offline, but prefers online)
  Future<void> logout() async {
    if (await _hasNetwork()) {
      final token = await _apiHelper.storage.read(key: StorageKeys.token);
      if (token != null) {
        final url = '${_apiHelper.baseUrl}/auth/logout';

        try {
          await _apiHelper.dio.post(
            url,
            options: Options(
              headers: {'Authorization': 'Bearer $token'},
            ),
          );
          _logger.i('User logged out successfully from server');
        } on DioException catch (e) {
          _logger.e('Server logout failed: ${e.message}');
          // Continue with local logout even if server fails
        }
      }
    } else {
      _logger.i('Offline logout - clearing local data only');
    }

    // Always clear local data
    await _clearAuth();
  }

  /// Check if user is logged in (works offline)
  Future<bool> isLoggedIn() async {
    final token = await _apiHelper.storage.read(key: StorageKeys.token);
    if (token == null || token.isEmpty) {
      return false;
    }

    // Check token expiry
    if (await _isTokenExpired()) {
      await _clearAuth();
      return false;
    }

    // If online, validate with server
    if (await _hasNetwork()) {
      final userDto = await _validateTokenAndGetUser();
      return userDto != null;
    } else {
      // Offline - check if we have cached user data
      final userJson = await _apiHelper.storage.read(key: StorageKeys.user);
      return userJson != null && userJson.isNotEmpty;
    }
  }

  /// Get user profile (works offline with cached data)
  Future<User?> getUser() async {
    // Try cached data first
    final userJson = await _apiHelper.storage.read(key: StorageKeys.user);
    if (userJson != null && userJson.isNotEmpty) {
      try {
        final userDto = UserDto.fromJson(jsonDecode(userJson));

        // Check if token is expired
        if (await _isTokenExpired()) {
          await _clearAuth();
          return null;
        }

        // If online, validate and update cache
        if (await _hasNetwork()) {
          final validatedUser = await _validateTokenAndGetUser();
          if (validatedUser != null) {
            return User(
              id: validatedUser.id,
              username: validatedUser.username,
              phoneNumber: validatedUser.phoneNumber,
              phoneVerified: validatedUser.phoneVerified,
              email: validatedUser.email,
              fcmToken: validatedUser.fcmToken,
            );
          }
          return null;
        }

        // Offline - return cached user
        return User(
          id: userDto.id,
          username: userDto.username,
          phoneNumber: userDto.phoneNumber,
          phoneVerified: userDto.phoneVerified,
          email: userDto.email,
          fcmToken: userDto.fcmToken,
        );
      } catch (e) {
        _logger.w("Failed to parse cached user data: $e. Clearing cache.");
        await _clearAuth();
      }
    }

    // No cached data and online - try to fetch from server
    if (await _hasNetwork()) {
      final userDto = await _validateTokenAndGetUser();
      if (userDto != null) {
        return User(
          id: userDto.id,
          username: userDto.username,
          phoneNumber: userDto.phoneNumber,
          phoneVerified: userDto.phoneVerified,
          email: userDto.email,
          fcmToken: userDto.fcmToken,
        );
      }
    }

    return null;
  }

  /// Get current token
  Future<String?> getToken() async {
    if (await _isTokenExpired()) {
      await _clearAuth();
      return null;
    }
    return await _apiHelper.storage.read(key: StorageKeys.token);
  }

  /// Stream for unauthenticated events
  Stream<void> get onUnauthenticated => _apiHelper.onUnauthenticated;

  /// Stream for no network events
  Stream<void> get onNoNetwork => _apiHelper.onNoNetwork;

  /// Update FCM token on backend. Call after successful login/register.
  Future<void> updateFCMToken(String fcmToken) async {
    if (!await _hasNetwork()) {
      _logger.i("No network, skipping FCM token update.");
      return;
    }

    final token = await getToken();
    if (token == null) {
      _logger.w("Cannot update FCM token: user is not authenticated.");
      return;
    }

    final url = '${_apiHelper.baseUrl}/auth/fcm-token';
    final request = UpdateFCMTokenRequest(fcmToken: fcmToken);

    try {
      final response = await _apiHelper.dio.put(
        url,
        data: request.toJson(),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Update cached user with new fcmToken
        final updatedUserDto = UserDto.fromJson(response.data['user']);
        await _apiHelper.storage.write(
          key: StorageKeys.user,
          value: jsonEncode(updatedUserDto.toJson()),
        );
        _logger.i('FCM token updated successfully on the backend.');
      } else {
        final error = response.data?['message'] ?? 'Failed to update FCM token';
        throw Exception(error);
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ??
          e.message ??
          'Failed to update FCM token';
      _logger.e("FCM token update failed: $message");
      throw Exception(message);
    } catch (e) {
      _logger.e("Unexpected error during FCM token update: $e");
      throw Exception(
          "An unexpected error occurred while updating the FCM token.");
    }
  }
}
