import 'package:flutter/material.dart';

class SnackbarUtil {
  static void showSuccess(BuildContext context, String message) {
    _showSnackbar(context, message, backgroundColor: Colors.green, icon: Icons.check_circle_outline);
  }

  static void showError(BuildContext context, String message) {
    _showSnackbar(context, message, backgroundColor: Colors.red, icon: Icons.error_outline);
  }

  static void showWarning(BuildContext context, String message) {
    _showSnackbar(context, message, backgroundColor: Colors.orange, icon: Icons.warning_amber_rounded);
  }

  static void showInfo(BuildContext context, String message) {
    _showSnackbar(context, message, backgroundColor: Colors.blueGrey, icon: Icons.info_outline);
  }

  static void _showSnackbar(BuildContext context, String message, {required Color backgroundColor, required IconData icon}) {
    ScaffoldMessenger.of(context).clearSnackBars(); // Limpia snackbars anteriores
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: backgroundColor,
        content: Row(
          children: [Icon(icon, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text(message, style: const TextStyle(color: Colors.white)))],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
