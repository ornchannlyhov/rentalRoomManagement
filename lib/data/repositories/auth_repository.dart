import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:receipts_v2/helpers/api_helper.dart';
import 'package:receipts_v2/data/dtos/user_dto.dart';
import 'package:receipts_v2/data/models/user.dart';

class StorageKeys {
  static const token = 'auth_token';
  static const user = 'user';
  static const tokenExpiry = 'token_expiry';
}

class RegisterRequest {
  final String username;
  final String email;
  final String password;

  RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'password': password,
      };
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class UpdatePasswordRequest {
  final String oldPassword;
  final String newPassword;

  UpdatePasswordRequest({
    required this.oldPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
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
            validateStatus: (status) => status! < 500, // Don't throw on 4xx
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
    if (expiryStr == null) return false; // If no expiry set, assume not expired

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

  /// Register user (requires network)
  Future<User> register(RegisterRequest request) async {
    if (!await _hasNetwork()) {
      throw Exception(
          "No internet connection. Registration requires network access.");
    }

    final url = '${_apiHelper.baseUrl}/auth/register';

    try {
      final response = await _apiHelper.dio.post(url, data: request.toJson());

      if (response.statusCode == 201 && response.data['success'] == true) {
        final token = response.data['token'] as String;
        final userDto = UserDto.fromJson(response.data['user']);

        await _apiHelper.storage.write(key: StorageKeys.token, value: token);
        await _apiHelper.storage.write(
          key: StorageKeys.user,
          value: jsonEncode(userDto.toJson()),
        );
        await _updateTokenExpiry();

        _logger.i('User registered successfully');
        return User(
          id: userDto.id,
          username: userDto.username,
          email: userDto.email,
          token: token,
        );
      } else {
        throw Exception('Registration failed: ${response.data}');
      }
    } on DioException catch (e) {
      _logger.e('Registration error: ${e.message}');
      final errorMessage = e.response?.data['message'] ??
          e.response?.data['error'] ??
          e.message ??
          'Registration failed';
      throw Exception(errorMessage);
    }
  }

  /// Login user (requires network)
  Future<User> login(LoginRequest request) async {
    if (!await _hasNetwork()) {
      throw Exception("No internet connection. Login requires network access.");
    }

    final url = '${_apiHelper.baseUrl}/auth/login';

    try {
      final response = await _apiHelper.dio.post(url, data: request.toJson());

      if (response.statusCode == 200 && response.data['success'] == true) {
        final token = response.data['token'] as String;
        final userDto = UserDto.fromJson(response.data['user']);

        await _apiHelper.storage.write(key: StorageKeys.token, value: token);
        await _apiHelper.storage.write(
          key: StorageKeys.user,
          value: jsonEncode(userDto.toJson()),
        );
        await _updateTokenExpiry();

        _logger.i('User logged in successfully');
        return User(
          id: userDto.id,
          username: userDto.username,
          email: userDto.email,
          token: token,
        );
      } else {
        throw Exception('Login failed: ${response.data}');
      }
    } on DioException catch (e) {
      _logger.e('Login error: ${e.message}');
      final errorMessage = e.response?.data['message'] ??
          e.response?.data['error'] ??
          e.message ??
          'Login failed';
      throw Exception(errorMessage);
    }
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

    final url = '${_apiHelper.baseUrl}/auth/update-password';

    try {
      final response = await _apiHelper.dio.put(
        url,
        data: request.toJson(),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
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
              email: validatedUser.email,
            );
          }
          return null;
        }

        // Offline - return cached user
        return User(
          id: userDto.id,
          username: userDto.username,
          email: userDto.email,
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
          email: userDto.email,
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
}
