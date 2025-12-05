import 'package:flutter/material.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';

class NetworkStatusProvider with ChangeNotifier {
  final ApiHelper _apiHelper = ApiHelper.instance;
  bool _isOnline = true;
  bool _hasChecked = false;

  NetworkStatusProvider() {
    _init();
  }

  bool get isOnline => _isOnline;
  bool get hasChecked => _hasChecked;

  void _init() {
    // Listen to network status changes from ApiHelper
    _apiHelper.onNetworkStatusChanged.listen((isOnline) {
      _hasChecked = true;
      if (_isOnline != isOnline) {
        _isOnline = isOnline;
        notifyListeners();
      }
    });

    // Initial check
    _checkNetworkStatus();
  }

  Future<void> _checkNetworkStatus() async {
    final hasNetwork = await _apiHelper.hasNetwork();
    _hasChecked = true;
    if (_isOnline != hasNetwork) {
      _isOnline = hasNetwork;
      notifyListeners();
    }
  }

  Future<void> checkAgain() async {
    await _checkNetworkStatus();
  }
}
