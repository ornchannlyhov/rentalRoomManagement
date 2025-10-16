import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:receipts_v2/helpers/api_helper.dart';
import 'package:receipts_v2/data/dtos/user_dto.dart';
import 'package:receipts_v2/data/models/user.dart';

class StorageKeys {
  static const token = 'auth_token';
  static const user = 'user';
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

  // Validate token and get user profile
  Future<UserDto?> _validateTokenAndGetUser() async {
    final token = await _apiHelper.storage.read(key: StorageKeys.token);
    if (token == null || token.isEmpty) return null;

    try {
      final response = await _apiHelper.dio.get(
        '${_apiHelper.baseUrl}/auth/profile',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final userDto = UserDto.fromJson(response.data['user']);
        await _apiHelper.storage.write(
          key: StorageKeys.user,
          value: jsonEncode(userDto.toJson()),
        );
        return userDto;
      } else {
        await _clearAuth();
        return null;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _clearAuth();
      }
      _logger.e("Token validation failed: ${e.message}");
      return null;
    } catch (e) {
      _logger.e("Unexpected error during token validation: $e");
      return null;
    }
  }

  // Clear authentication data
  Future<void> _clearAuth() async {
    await _apiHelper.storage.delete(key: StorageKeys.token);
    await _apiHelper.storage.delete(key: StorageKeys.user);
  }

  // Register user
  Future<User> register(RegisterRequest request) async {
    if (!await _hasNetwork()) {
      throw Exception("No internet connection.");
    }

    final url = '${_apiHelper.baseUrl}/auth/register';

    try {
      final response = await _apiHelper.dio.post(url, data: request.toJson());

      if (response.statusCode == 201 && response.data['success'] == true) {
        final token = response.data['token'] as String;
        final userDto = UserDto.fromJson(response.data['user']);

        // Store token and user data
        await _apiHelper.storage.write(key: StorageKeys.token, value: token);
        await _apiHelper.storage.write(
          key: StorageKeys.user,
          value: jsonEncode(userDto.toJson()),
        );

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

  // Login user
  Future<User> login(LoginRequest request) async {
    if (!await _hasNetwork()) {
      throw Exception("No internet connection.");
    }

    final url = '${_apiHelper.baseUrl}/auth/login';

    try {
      final response = await _apiHelper.dio.post(url, data: request.toJson());

      if (response.statusCode == 200 && response.data['success'] == true) {
        final token = response.data['token'] as String;
        final userDto = UserDto.fromJson(response.data['user']);

        // Store token and user data
        await _apiHelper.storage.write(key: StorageKeys.token, value: token);
        await _apiHelper.storage.write(
          key: StorageKeys.user,
          value: jsonEncode(userDto.toJson()),
        );

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

  // Update password
  Future<void> updatePassword(UpdatePasswordRequest request) async {
    if (!await _hasNetwork()) {
      throw Exception("No internet connection.");
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

  // Logout user
  Future<void> logout() async {
    if (!await _hasNetwork()) {
      throw Exception("No internet connection.");
    }

    final token = await _apiHelper.storage.read(key: StorageKeys.token);
    if (token == null) {
      await _clearAuth();
      return;
    }

    final url = '${_apiHelper.baseUrl}/auth/logout';

    try {
      final response = await _apiHelper.dio.post(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        await _clearAuth();
        _logger.i('User logged out successfully');
      } else {
        throw Exception('Logout failed: ${response.data}');
      }
    } on DioException catch (e) {
      _logger.e('Logout error: ${e.message}');
      await _clearAuth(); // Clear local data even if server logout fails
      throw Exception(e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Logout failed');
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _apiHelper.storage.read(key: StorageKeys.token);
    if (token == null || token.isEmpty) {
      return false;
    }

    if (await _hasNetwork()) {
      final userDto = await _validateTokenAndGetUser();
      return userDto != null;
    } else {
      final userJson = await _apiHelper.storage.read(key: StorageKeys.user);
      return userJson != null && userJson.isNotEmpty;
    }
  }

  // Get user profile
  Future<User?> getUser() async {
    final userJson = await _apiHelper.storage.read(key: StorageKeys.user);
    if (userJson != null) {
      try {
        final userDto = UserDto.fromJson(jsonDecode(userJson));
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

  // Get current token
  Future<String?> getToken() async {
    return await _apiHelper.storage.read(key: StorageKeys.token);
  }

  // Stream for unauthenticated events
  Stream<void> get onUnauthenticated => _apiHelper.onUnauthenticated;

  // Stream for no network events
  Stream<void> get onNoNetwork => _apiHelper.onNoNetwork;
}
