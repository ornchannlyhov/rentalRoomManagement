import 'package:flutter/material.dart';

class AppbarCustom extends StatelessWidget implements PreferredSizeWidget {
  final String header;
  final VoidCallback onAddPressed;

  const AppbarCustom({
    super.key,
    required this.header,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      title: Text(header, style: theme.appBarTheme.titleTextStyle),
      actions: [
        IconButton(
          onPressed: onAddPressed,
          icon: Icon(Icons.add, color: theme.iconTheme.color),
        ),
      ],
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: theme.appBarTheme.elevation ?? 0,
      shadowColor: theme.appBarTheme.shadowColor,
      centerTitle: false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
