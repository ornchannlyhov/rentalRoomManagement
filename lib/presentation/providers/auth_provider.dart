import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receipts_v2/core/asyn_value.dart';
import 'package:receipts_v2/data/models/user.dart';
import 'package:receipts_v2/data/repositories/auth_repository.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _repository;

  late final StreamSubscription _unauthenticatedSubscription;
  late final StreamSubscription _noNetworkSubscription;

  AuthProvider(this._repository) {
    _unauthenticatedSubscription = _repository.onUnauthenticated.listen(
      (_) => _handleSessionExpired(),
    );

    _noNetworkSubscription = _repository.onNoNetwork.listen(
      (_) => _handleNoNetwork(),
    );
  }

  // State variables
  AsyncValue<User?> _user = const AsyncValue.loading();
  AsyncValue<bool> _loginState = const AsyncValue.success(false);
  AsyncValue<bool> _registerState = const AsyncValue.success(false);
  AsyncValue<bool> _passwordUpdateState = const AsyncValue.success(false);
  bool _sessionHasExpired = false;
  bool _showNetworkError = false;

  // Getters
  AsyncValue<User?> get user => _user;
  AsyncValue<bool> get loginState => _loginState;
  AsyncValue<bool> get registerState => _registerState;
  AsyncValue<bool> get passwordUpdateState => _passwordUpdateState;
  bool get sessionHasExpired => _sessionHasExpired;
  bool get showNetworkError => _showNetworkError;

  // Initialize app - check if user is logged in
  Future<void> load() async {
    _user = const AsyncValue.loading();
    notifyListeners();

    try {
      final isLoggedIn = await _repository.isLoggedIn();
      if (isLoggedIn) {
        final userData = await _repository.getUser();
        _user = AsyncValue.success(userData);
      } else {
        _user = const AsyncValue.success(null);
      }
    } catch (e) {
      _user = AsyncValue.error(e);
      debugPrint('Initialization error: $e');
    }

    notifyListeners();
  }

  // Register
  Future<void> register(RegisterRequest request) async {
    _registerState = const AsyncValue.loading();
    notifyListeners();

    try {
      final newUser = await _repository.register(request);
      _user = AsyncValue.success(newUser);
      _registerState = const AsyncValue.success(true);
    } catch (e) {
      _user = const AsyncValue.success(null);
      _registerState = AsyncValue.error(_mapExceptionToMessage(e));
    }

    notifyListeners();
  }

  // Login
  Future<void> login(LoginRequest request) async {
    _loginState = const AsyncValue.loading();
    notifyListeners();

    try {
      final loggedInUser = await _repository.login(request);
      _user = AsyncValue.success(loggedInUser);
      _loginState = const AsyncValue.success(true);
    } catch (e) {
      _user = const AsyncValue.success(null);
      _loginState = AsyncValue.error(_mapExceptionToMessage(e));
    }

    notifyListeners();
  }

  // Update password
  Future<void> updatePassword(UpdatePasswordRequest request) async {
    _passwordUpdateState = const AsyncValue.loading();
    notifyListeners();

    try {
      await _repository.updatePassword(request);
      _passwordUpdateState = const AsyncValue.success(true);
    } catch (e) {
      _passwordUpdateState = AsyncValue.error(_mapExceptionToMessage(e));
    }

    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _user = const AsyncValue.success(null);
      _loginState = const AsyncValue.success(false);
      _sessionHasExpired = false;
      notifyListeners();
    }
  }

  // Get profile (refresh user data)
  Future<void> getProfile() async {
    try {
      final profile = await _repository.getUser();
      if (profile != null) {
        _user = AsyncValue.success(profile);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error getting profile: $e');
      if (e.toString().contains('token') ||
          e.toString().contains('unauthorized') ||
          e.toString().contains('expired')) {
        await _handleSessionExpired();
      }
    }
  }

  // Get current user synchronously
  User? getCurrentUser() {
    return _user.when(
      loading: () => null,
      success: (user) => user,
      error: (_) => null,
    );
  }

  // Check if authenticated
  bool isAuthenticated() {
    return _user.when(
      loading: () => false,
      success: (user) => user != null,
      error: (_) => false,
    );
  }

  // Get token
  Future<String?> getToken() async {
    return await _repository.getToken();
  }

  // Reset login state (useful after showing error messages)
  void resetLoginState() {
    _loginState = const AsyncValue.success(false);
    notifyListeners();
  }

  // Reset register state
  void resetRegisterState() {
    _registerState = const AsyncValue.success(false);
    notifyListeners();
  }

  // Reset password update state
  void resetPasswordUpdateState() {
    _passwordUpdateState = const AsyncValue.success(false);
    notifyListeners();
  }

  // Error handling
  void acknowledgeNetworkError() {
    _showNetworkError = false;
    if (_loginState.isLoading) {
      _loginState = const AsyncValue.success(false);
    }
    if (_registerState.isLoading) {
      _registerState = const AsyncValue.success(false);
    }
    notifyListeners();
  }

  void acknowledgeSessionExpired() {
    _sessionHasExpired = false;
    notifyListeners();
  }

  // Private helpers
  Future<void> _handleSessionExpired() async {
    if (isAuthenticated()) {
      _user = const AsyncValue.success(null);
      _sessionHasExpired = true;
      notifyListeners();
    }
  }

  void _handleNoNetwork() {
    _showNetworkError = true;
    notifyListeners();
  }

  String _mapExceptionToMessage(dynamic e) {
    final errorMessage = e.toString();

    if (errorMessage.contains('No internet connection')) {
      return "No internet connection. Please check your network.";
    } else if (errorMessage.contains('Not authenticated')) {
      return "You are not logged in. Please login.";
    } else if (errorMessage.contains('email') ||
        errorMessage.contains('password')) {
      return errorMessage.replaceAll('Exception: ', '');
    } else if (errorMessage.contains('Authentication failed')) {
      return "Login failed. Please check your credentials and try again.";
    } else if (errorMessage.contains('Logout failed')) {
      return "Logout failed. Please try again.";
    } else if (errorMessage.contains('Password')) {
      return errorMessage.replaceAll('Exception: ', '');
    }

    return errorMessage.replaceAll('Exception: ', '');
  }

  @override
  void dispose() {
    _unauthenticatedSubscription.cancel();
    _noNetworkSubscription.cancel();
    super.dispose();
  }
}
