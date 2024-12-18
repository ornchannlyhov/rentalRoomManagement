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
    return AppBar(
      title: Text(
        header,
        style: const TextStyle(color: Colors.white),
      ),
      actions: [
        IconButton(
          onPressed: onAddPressed,
          icon: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
      ],
      backgroundColor: const Color(0xFF1A0C2D),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
