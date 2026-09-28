import 'package:flutter/material.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';

class NetworkStatusProvider with ChangeNotifier {
  final ApiHelper _apiHelper = ApiHelper.instance;
  bool _isOnline = true;
  bool _isServerDown = false;
  bool _hasChecked = false;

  NetworkStatusProvider() {
    _init();
  }

  bool get isOnline => _isOnline;
  bool get hasChecked => _hasChecked;

  /// Connected, but our server didn't answer.
  bool get isServerDown => _isServerDown;

  void _init() {
    // Listen to network status changes from ApiHelper
    _apiHelper.onNetworkStatusChanged.listen((isOnline) {
      _hasChecked = true;
      if (_isOnline != isOnline ||
          _isServerDown != _apiHelper.isServerDown) {
        _isOnline = isOnline;
        _isServerDown = _apiHelper.isServerDown;
        notifyListeners();
      }
    });

    // Initial check
    _checkNetworkStatus();
  }

  Future<void> _checkNetworkStatus() async {
    final hasNetwork = await _apiHelper.hasNetwork();
    _hasChecked = true;
    if (_isOnline != hasNetwork || _isServerDown != _apiHelper.isServerDown) {
      _isOnline = hasNetwork;
      _isServerDown = _apiHelper.isServerDown;
      notifyListeners();
    }
  }

  Future<void> checkAgain() async {
    await _checkNetworkStatus();
  }
}
