// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:joul_v2/core/helpers/repository_manager.dart';
import 'package:joul_v2/presentation/providers/auth_provider.dart';
import 'package:joul_v2/presentation/providers/building_provider.dart';
import 'package:joul_v2/presentation/providers/receipt_provider.dart';
import 'package:joul_v2/presentation/providers/report_provider.dart';
import 'package:joul_v2/presentation/providers/service_provider.dart';
import 'package:joul_v2/presentation/providers/tenant_provider.dart';
import 'package:joul_v2/presentation/view/app_widgets/app_menu.dart';
import 'package:joul_v2/presentation/view/app_widgets/global_snackbar.dart';
import 'package:joul_v2/presentation/view/screen/auth/onboard_screen.dart';
import 'package:joul_v2/presentation/view/screen/building/building_screen.dart';
import 'package:joul_v2/presentation/view/screen/history/history_screen.dart';
import 'package:joul_v2/presentation/view/screen/receipt/receipt_screen.dart';
import 'package:joul_v2/presentation/view/screen/setting/profile_screen.dart';
import 'package:joul_v2/presentation/view/screen/tenant/tenant_screen.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final Logger _logger = Logger();
  Timer? _syncTimer;
  bool _isSyncing = false;
  bool _hasShownNetworkError = false;

  @override
  void initState() {
    super.initState();
    _setupNetworkListeners();
    _startPeriodicSync();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  void _setupNetworkListeners() {
    final apiHelper = ApiHelper.instance;

    // Listen for unauthenticated events
    apiHelper.onUnauthenticated.listen((_) {
      if (mounted) {
        _showSessionExpiredDialog();
      }
    });

    // Listen for network loss
    apiHelper.onNoNetwork.listen((_) {
      if (mounted && !_hasShownNetworkError) {
        _hasShownNetworkError = true;
        GlobalSnackBar.show(
          context: context,
          message: 'No internet connection. Changes will be saved locally.',
          isError: true,
        );
      }
    });

    // Listen for network restoration
    apiHelper.onNetworkStatusChanged.listen((hasNetwork) {
      if (mounted) {
        if (hasNetwork) {
          _hasShownNetworkError = false;
          _syncDataWhenNetworkRestored();
        } else if (!_hasShownNetworkError) {
          _hasShownNetworkError = true;
          GlobalSnackBar.show(
            context: context,
            message: 'No internet connection. Changes will be saved locally.',
            isError: true,
          );
        }
      }
    });

    // Check for existing session expiryz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.sessionHasExpired) {
        _showSessionExpiredDialog();
      }
    });
  }

  void _startPeriodicSync() {
    // Sync every 5 minutes if authenticated and online
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _performBackgroundSync();
    });
  }

  Future<void> _performBackgroundSync() async {
    if (_isSyncing) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final repositoryManager =
        Provider.of<RepositoryManager>(context, listen: false);

    if (!authProvider.isAuthenticated()) return;
    if (!await ApiHelper.instance.hasNetwork()) return;

    _isSyncing = true;
    try {
      _logger.i('Performing background sync...');
      await repositoryManager.syncAll();
      _logger.i('Background sync completed');
    } catch (e) {
      _logger.e('Background sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncDataWhenNetworkRestored() async {
    if (_isSyncing) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final repositoryManager =
        Provider.of<RepositoryManager>(context, listen: false);

    if (!authProvider.isAuthenticated()) return;

    _isSyncing = true;
    try {
      _logger.i('Network restored, syncing all data...');

      final success = await repositoryManager.syncAll();

      if (success && mounted) {
        // Refresh all providers
        Provider.of<BuildingProvider>(context, listen: false).load();
        Provider.of<ServiceProvider>(context, listen: false).load();
        Provider.of<TenantProvider>(context, listen: false).load();
        Provider.of<ReceiptProvider>(context, listen: false).load();
        Provider.of<ReportProvider>(context, listen: false).load();

        GlobalSnackBar.show(
          context: context,
          message: 'Connection restored. Data synced successfully.',
        );

        _logger.i('All data synced after network restoration');
      } else if (mounted) {
        GlobalSnackBar.show(
          context: context,
          message: 'Sync completed with some errors',
          isError: true,
          onRestore: () async {
            // Retry sync
            await _syncDataWhenNetworkRestored();
          },
        );
      }
    } catch (e) {
      _logger.e('Failed to sync after network restore: $e');
      if (mounted) {
        GlobalSnackBar.show(
          context: context,
          message: 'Sync failed. Using cached data.',
          isError: true,
          onRestore: () async {
            // Retry sync
            await _syncDataWhenNetworkRestored();
          },
        );
      }
    } finally {
      _isSyncing = false;
    }
  }

  bool _hasShownSessionExpiredDialog = false;

  void _showSessionExpiredDialog() {
    // Prevent showing dialog multiple times
    if (_hasShownSessionExpiredDialog) return;
    _hasShownSessionExpiredDialog = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text('Your session has expired. Please log in again.'),
        actions: [
          TextButton(
            onPressed: () async {
              // Get providers before any async operations
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final repositoryManager =
                  Provider.of<RepositoryManager>(context, listen: false);

              // Clear all cached data - same as logout flow
              await authProvider.logout();
              await repositoryManager.clearAll();

              authProvider.acknowledgeSessionExpired();
              _hasShownSessionExpiredDialog = false;

              if (mounted) {
                Navigator.of(context).pop();
                // Navigate to onboarding screen, not login (same as logout)
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/onboarding',
                  (route) => false,
                );
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Network error dialog removed - using offline banner instead

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show session expired dialog if needed
        // Network errors use the offline banner in main.dart, no dialog needed
        if (authProvider.sessionHasExpired) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showSessionExpiredDialog();
          });
        }

        // Check authentication
        if (authProvider.isAuthenticated()) {
          return const MainScreen();
        }

        return authProvider.user.when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          success: (user) {
            if (user != null) {
              return const MainScreen();
            } else {
              return const OnboardingScreen();
            }
          },
          error: (error) => const OnboardingScreen(),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ReceiptScreen(),
    const HistoryScreen(),
    const BuildingScreen(),
    const TenantScreen(),
    const ProfileScreen(),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: _screens[_currentIndex]),
          AppMenu(
            selectedIndex: _currentIndex,
            onTap: _onTabSelected,
          ),
        ],
      ),
    );
  }
}
