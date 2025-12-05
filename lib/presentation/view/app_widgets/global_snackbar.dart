import 'package:flutter/material.dart';

class GlobalSnackBar {
  static void show({
    required BuildContext context,
    required String message,
    bool isError = false,
    VoidCallback? onRestore,
  }) {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        margin: const EdgeInsets.only(
          bottom: kBottomNavigationBarHeight + 12,
          left: 12,
          right: 12,
        ),
        duration: const Duration(seconds: 3),
        backgroundColor:
            isError ? theme.colorScheme.error : theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: isError
                ? theme.colorScheme.onError
                : theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        action: onRestore != null
            ? SnackBarAction(
                label: 'UNDO',
                textColor: isError
                    ? theme.colorScheme.onError
                    : theme.colorScheme.onPrimary,
                onPressed: onRestore,
              )
            : SnackBarAction(
                label: '',
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                textColor: Colors.transparent,
              ),
        showCloseIcon: true,
        closeIconColor:
            isError ? theme.colorScheme.onError : theme.colorScheme.onPrimary,
      ),
    );
  }
}
