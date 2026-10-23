import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/utils/globals.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:flutter/material.dart';

class SnackbarUtil {
  SnackbarUtil._();

  static void showSuccess(BuildContext? context, String message) {
    _showSnackbar(context, message, backgroundColor: AppColors.kSuccess, icon: Icons.check_circle_outline);
  }

  static void showError(BuildContext? context, String message) {
    _showSnackbar(context, message, backgroundColor: Colors.red.shade700, icon: Icons.error_outline);
  }

  static void showWarning(BuildContext? context, String message) {
    _showSnackbar(context, message, backgroundColor: Colors.orange.shade800, icon: Icons.warning_amber_rounded);
  }

  static void showInfo(BuildContext? context, String message) {
    _showSnackbar(context, message, backgroundColor: AppColors.kNeutral800, icon: Icons.info_outline);
  }

  static void _showSnackbar(BuildContext? context, String message, {required Color backgroundColor, required IconData icon}) {
    final messenger = context != null && context.mounted
        ? ScaffoldMessenger.maybeOf(context) ?? scaffoldMessengerKey.currentState
        : scaffoldMessengerKey.currentState;

    if (messenger == null) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: AppText(
                message,
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
