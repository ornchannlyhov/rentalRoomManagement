import 'dart:async';
import 'package:flutter/material.dart';
import 'package:joul_v2/core/helpers/asyn_value.dart';
import 'package:joul_v2/data/models/user.dart';
import 'package:joul_v2/data/repositories/auth_repository.dart';
import 'package:joul_v2/core/helpers/repository_manager.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _repository;
  final RepositoryManager? _repositoryManager;

  late final StreamSubscription _unauthenticatedSubscription;
  late final StreamSubscription _noNetworkSubscription;
  bool _disposed = false;

  AuthProvider(this._repository, {RepositoryManager? repositoryManager})
      : _repositoryManager = repositoryManager {
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
  AsyncValue<bool> _otpState = const AsyncValue.success(false);
  AsyncValue<bool> _passwordUpdateState = const AsyncValue.success(false);
  AsyncValue<bool> _passwordResetState = const AsyncValue.success(false);
  AsyncValue<bool> _passwordResetVerifyState = const AsyncValue.success(false);
  bool _sessionHasExpired = false;
  bool _showNetworkError = false;
  bool _otpSent = false;

  // Getters
  AsyncValue<User?> get user => _user;
  AsyncValue<bool> get loginState => _loginState;
  AsyncValue<bool> get registerState => _registerState;
  AsyncValue<bool> get otpState => _otpState;
  AsyncValue<bool> get passwordUpdateState => _passwordUpdateState;
  AsyncValue<bool> get passwordResetState => _passwordResetState;
  AsyncValue<bool> get passwordResetVerifyState => _passwordResetVerifyState;
  bool get sessionHasExpired => _sessionHasExpired;
  bool get showNetworkError => _showNetworkError;
  bool get otpSent => _otpSent;

  // Initialize app - check if user is logged in
  Future<void> load() async {
    try {
      _user = const AsyncValue.loading();
      notifyListeners();

      final isLoggedIn = await _repository.isLoggedIn();

      if (isLoggedIn) {
        final user = await _repository.getUser();
        if (user != null) {
          _user = AsyncValue.success(user);
        } else {
          _user = const AsyncValue.success(null);
        }
      } else {
        _user = const AsyncValue.success(null);
      }

      notifyListeners();
    } catch (e) {
      _user = AsyncValue.error(e);
      notifyListeners();
    }
  }

  // --- Registration Flow ---

  Future<void> requestRegistration(RequestRegistrationRequest request) async {
    _registerState = const AsyncValue.loading();
    _otpSent = false;
    notifyListeners();

    try {
      await _repository.requestRegistration(request);
      _otpSent = true;
      _registerState = const AsyncValue.success(true);
    } catch (e) {
      _otpSent = false;
      _registerState = AsyncValue.error(_mapExceptionToMessage(e));
    }

    notifyListeners();
  }

  Future<void> verifyRegistration(VerifyRegistrationRequest request) async {
    _otpState = const AsyncValue.loading();
    notifyListeners();

    try {
      final newUser = await _repository.verifyRegistration(request);
      _user = AsyncValue.success(newUser);
      _otpState = const AsyncValue.success(true);
      _otpSent = false; // Reset after successful verification
    } catch (e) {
      _user = const AsyncValue.success(null);
      _otpState = AsyncValue.error(_mapExceptionToMessage(e));
    }

    notifyListeners();
  }

  // --- Login Flow ---

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

  // --- Password Reset Flow ---

  Future<void> requestPasswordReset(RequestPasswordResetRequest request) async {
    _passwordResetState = const AsyncValue.loading();
    _otpSent = false;
    notifyListeners();

    try {
      await _repository.requestPasswordReset(request);
      _otpSent = true;
      _passwordResetState = const AsyncValue.success(true);
    } catch (e) {
      _otpSent = false;
      _passwordResetState = AsyncValue.error(_mapExceptionToMessage(e));
    }

    notifyListeners();
  }

  Future<void> verifyPasswordReset(VerifyPasswordResetRequest request) async {
    _passwordResetVerifyState = const AsyncValue.loading();
    notifyListeners();

    try {
      await _repository.verifyPasswordReset(request);
      _passwordResetVerifyState = const AsyncValue.success(true);
      _otpSent = false;
    } catch (e) {
      _passwordResetVerifyState = AsyncValue.error(_mapExceptionToMessage(e));
    }

    notifyListeners();
  }

  // --- Resend OTP ---

  Future<void> resendOtp(String phoneNumber, String purpose) async {
    try {
      final request = ResendOtpRequest(
        phoneNumber: phoneNumber,
        purpose: purpose,
      );
      await _repository.resendOtp(request);
    } catch (e) {
      debugPrint("Resend OTP failed: $e");
    }
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
      rethrow;
    }

    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    try {
      await _repository.logout();

      // Clear all cached data
      if (_repositoryManager != null) {
        await _repositoryManager.clearAll();
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      if (!_disposed) {
        _user = const AsyncValue.success(null);
        _loginState = const AsyncValue.success(false);
        _otpState = const AsyncValue.success(false);
        _otpSent = false;
        _sessionHasExpired = false;
        notifyListeners();
      }
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

  // Reset OTP state
  void resetOtpState() {
    _otpState = const AsyncValue.success(false);
    notifyListeners();
  }

  // Reset password reset state
  void resetPasswordResetState() {
    _passwordResetState = const AsyncValue.success(false);
    notifyListeners();
  }

  // Reset password reset verify state
  void resetPasswordResetVerifyState() {
    _passwordResetVerifyState = const AsyncValue.success(false);
    notifyListeners();
  }

  void acknowledgeNetworkError() {
    _showNetworkError = false;
    if (_loginState.isLoading) {
      _loginState = const AsyncValue.success(false);
    }
    if (_registerState.isLoading) {
      _registerState = const AsyncValue.success(false);
    }
    if (_otpState.isLoading) {
      _otpState = const AsyncValue.success(false);
    }
    if (_passwordResetState.isLoading) {
      _passwordResetState = const AsyncValue.success(false);
    }
    if (_passwordResetVerifyState.isLoading) {
      _passwordResetVerifyState = const AsyncValue.success(false);
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
    } else if (errorMessage.contains('OTP')) {
      return errorMessage.replaceAll('Exception: ', '');
    }

    return errorMessage.replaceAll('Exception: ', '');
  }

  @override
  void dispose() {
    _disposed = true;
    _unauthenticatedSubscription.cancel();
    _noNetworkSubscription.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}
