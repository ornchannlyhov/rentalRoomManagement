import 'package:flutter/material.dart';
import 'package:receipts_v2/core/asyn_value.dart';
import 'package:receipts_v2/data/models/user.dart';
import 'package:receipts_v2/data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthProvider(this._repository);

  AsyncValue<User?> _user = const AsyncValue.loading();
  AsyncValue<User?> get user => _user;

  Future<void> load() async {
    _user = const AsyncValue.loading();
    notifyListeners();
    try {
      await _repository.load();
      final data = _repository.getCurrentUser();
      _user = AsyncValue.success(data);
    } catch (e) {
      _user = AsyncValue.error(e);
    }
    notifyListeners();
  }

  Future<void> register(RegisterRequest request) async {
    _user = const AsyncValue.loading();
    notifyListeners();
    try {
      final newUser = await _repository.register(request);
      _user = AsyncValue.success(newUser);
    } catch (e) {
      _user = AsyncValue.error(e);
    }
    notifyListeners();
  }

  Future<void> login(LoginRequest request) async {
    _user = const AsyncValue.loading();
    notifyListeners();
    try {
      final loggedInUser = await _repository.login(request);
      _user = AsyncValue.success(loggedInUser);
    } catch (e) {
      _user = AsyncValue.error(e);
    }
    notifyListeners();
  }

  Future<void> updatePassword(UpdatePasswordRequest request) async {
    try {
      await _repository.updatePassword(request);
      // No need to update user state, as password update doesn't change user data
    } catch (e) {
      _user = AsyncValue.error(e);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
      _user = const AsyncValue.success(null);
    } catch (e) {
      _user = AsyncValue.error(e);
    }
    notifyListeners();
  }

  Future<void> getProfile() async {
    _user = const AsyncValue.loading();
    notifyListeners();
    try {
      final profile = await _repository.getProfile();
      _user = AsyncValue.success(profile);
    } catch (e) {
      _user = AsyncValue.error(e);
    }
    notifyListeners();
  }

  bool isAuthenticated() {
    return _repository.isAuthenticated();
  }
}