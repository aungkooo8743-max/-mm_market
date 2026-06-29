import 'package:flutter/material.dart';

class AppSnackbar {
  const AppSnackbar._();

  static void success(BuildContext context, String message) => _show(context, message, Icons.check_circle_outline);
  static void error(BuildContext context, String message) => _show(context, message, Icons.error_outline);
  static void info(BuildContext context, String message) => _show(context, message, Icons.info_outline);

  static void _show(BuildContext context, String message, IconData icon) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Row(children: [Icon(icon, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text(message))])));
  }
}
