import 'package:flutter/material.dart';

class NavigationService {
  static Future<void> navigateTo(BuildContext context, String route, {Object? arguments}) async {
    if (context.mounted) {
      Navigator.of(context).pushNamed(route, arguments: arguments);
    }
  }

  static Future<void> replaceWith(BuildContext context, String route, {Object? arguments}) async {
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed(route, arguments: arguments);
    }
  }

  static Future<void> replaceUntil(BuildContext context, String route, {Object? arguments}) async {
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(route, (Route<dynamic> route) => false, arguments: arguments);
    }
  }

  static void pop(BuildContext context) {
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
