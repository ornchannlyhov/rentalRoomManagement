import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:receipts_v2/data/models/user.dart';

class AuthRepository {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String storageKey = 'user_secure_data';
  final String baseUrl = 'http://localhost:80/api';
  final Logger _logger = Logger();
  User? _userCache;

  Future<void> load() async {
    try {
      _logger.i('Loading user data from secure storage');
      final jsonString = await _secureStorage.read(key: storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        _logger.d('Found user data in secure storage: $jsonString');
        final jsonData = jsonDecode(jsonString);
        _userCache = User.fromJson(jsonData);
        _logger.i('User data loaded successfully');
      } else {
        _logger.w('No user data found in secure storage');
        _userCache = null;
      }
    } catch (e) {
      _logger.e('Failed to load user data from secure storage: $e');
      throw Exception('Failed to load user data from secure storage: $e');
    }
  }

  Future<void> save() async {
    try {
      if (_userCache != null) {
        _logger.i('Saving user data to secure storage');
        final jsonString = jsonEncode(_userCache!.toJson());
        await _secureStorage.write(key: storageKey, value: jsonString);
        _logger.d('User data saved successfully: $jsonString');
      } else {
        _logger.i('Deleting user data from secure storage');
        await _secureStorage.delete(key: storageKey);
        _logger.d('User data deleted successfully');
      }
    } catch (e) {
      _logger.e('Failed to save user data to secure storage: $e');
      throw Exception('Failed to save user data to secure storage: $e');
    }
  }

  Future<User> register(RegisterRequest request) async {
    try {
      _logger
          .i('Attempting to register user with request: ${request.toJson()}');

      final uri = Uri.parse('$baseUrl/auth/register');
      _logger.d('Request URI: $uri');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      _logger.d('Request headers: $headers');

      final body = jsonEncode(request.toJson());
      _logger.d('Request body: $body');

      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      );

      _logger.d('Response status code: ${response.statusCode}');
      _logger.d('Response headers: ${response.headers}');
      _logger.d('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        _userCache = User.fromJson(jsonData);
        await save();
        _logger.i('User registered successfully: ${_userCache!.toJson()}');
        return _userCache!;
      } else if (response.statusCode == 400) {
        String errorMessage = 'Invalid registration data';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage =
              errorData['message'] ?? errorData['error'] ?? errorMessage;
          _logger.w('Bad request during registration: $errorMessage');
          _logger.d('Full error response: ${response.body}');
        } catch (e) {
          _logger.w('Could not parse error response: ${response.body}');
        }
        throw Exception('Bad request: $errorMessage');
      } else {
        _logger.e(
            'Failed to register user: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Failed to register user: Server returned ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Bad request:')) {
        rethrow; // Preserve the original error message for 400 errors
      }
      _logger.e('Failed to register user: $e');
      throw Exception('Failed to register user: $e');
    }
  }

  Future<User> login(LoginRequest request) async {
    try {
      _logger.i('Attempting to login with request: ${request.toJson()}');

      final uri = Uri.parse('$baseUrl/auth/login');
      _logger.d('Request URI: $uri');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final body = jsonEncode(request.toJson());
      _logger.d('Request body: $body');

      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      );

      _logger.d('Response status code: ${response.statusCode}');
      _logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        _userCache = User.fromJson(jsonData);
        await save();
        _logger.i('User logged in successfully: ${_userCache!.toJson()}');
        return _userCache!;
      } else if (response.statusCode == 400) {
        String errorMessage = 'Invalid credentials';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage =
              errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (e) {
          _logger.w('Could not parse error response: ${response.body}');
        }
        _logger.w('Invalid credentials during login: $errorMessage');
        throw Exception(errorMessage);
      } else {
        _logger.e('Failed to login: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Failed to login: Server returned ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to login: $e');
      throw Exception('Failed to login: $e');
    }
  }

  Future<void> updatePassword(UpdatePasswordRequest request) async {
    try {
      if (_userCache == null || _userCache!.token == null) {
        _logger.w('No authenticated user found for password update');
        throw Exception('No authenticated user found');
      }

      _logger
          .i('Attempting to update password for user: ${_userCache!.toJson()}');
      final response = await http.put(
        Uri.parse('$baseUrl/auth/update-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_userCache!.token}',
        },
        body: jsonEncode(request.toJson()),
      );

      _logger.d('Response status code: ${response.statusCode}');
      _logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        _logger.i('Password updated successfully');
      } else if (response.statusCode == 400) {
        String errorMessage = 'Invalid password data';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage =
              errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (e) {
          _logger.w('Could not parse error response: ${response.body}');
        }
        _logger.w('Bad request during password update: $errorMessage');
        throw Exception('Bad request: $errorMessage');
      } else {
        _logger.e(
            'Failed to update password: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Failed to update password: Server returned ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to update password: $e');
      throw Exception('Failed to update password: $e');
    }
  }

  Future<void> logout() async {
    try {
      if (_userCache == null || _userCache!.token == null) {
        _logger.w('No authenticated user found for logout');
        throw Exception('No authenticated user found');
      }

      _logger.i('Attempting to logout user: ${_userCache!.toJson()}');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {
          'Authorization': 'Bearer ${_userCache!.token}',
        },
      );

      if (response.statusCode == 200) {
        _userCache = null;
        await save();
        _logger.i('User logged out successfully');
      } else {
        _logger.e('Failed to logout: ${response.statusCode}');
        throw Exception('Failed to logout: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to logout: $e');
      throw Exception('Failed to logout: $e');
    }
  }

  Future<User> getProfile() async {
    try {
      if (_userCache == null || _userCache!.token == null) {
        _logger.w('No authenticated user found for profile retrieval');
        throw Exception('No authenticated user found');
      }

      _logger.i('Retrieving profile for user: ${_userCache!.toJson()}');
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Authorization': 'Bearer ${_userCache!.token}',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        _userCache = User.fromJson(jsonData);
        await save();
        _logger.i('Profile retrieved successfully: ${_userCache!.toJson()}');
        return _userCache!;
      } else if (response.statusCode == 404) {
        _logger.w('User not found during profile retrieval');
        throw Exception('User not found');
      } else {
        _logger.e('Failed to retrieve profile: ${response.statusCode}');
        throw Exception('Failed to retrieve profile: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to retrieve profile: $e');
      throw Exception('Failed to retrieve profile: $e');
    }
  }

  User? getCurrentUser() {
    _logger.d('Getting current user: ${_userCache?.toJson() ?? 'null'}');
    return _userCache;
  }

  bool isAuthenticated() {
    final authenticated = _userCache != null && _userCache!.token != null;
    _logger.d('Checking authentication status: $authenticated');
    return authenticated;
  }
}
