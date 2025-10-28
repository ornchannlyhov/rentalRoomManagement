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
        padding: const EdgeInsets.fromLTRB(16.0, 4.0, 4.0, 4.0),
        content: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isError
                      ? theme.colorScheme.onError
                      : theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onRestore != null)
              IconButton(
                icon: Icon(
                  Icons.restore,
                  color: isError
                      ? theme.colorScheme.onError
                      : theme.colorScheme.onPrimary,
                  size: 20,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onRestore();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 20,
              )
            else
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: isError
                      ? theme.colorScheme.onError
                      : theme.colorScheme.onPrimary,
                  size: 20,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 20,
              ),
          ],
        ),
      ),
    );
  }
}
