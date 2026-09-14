import 'package:flutter/material.dart';

class NavigationService {
  static Future<T?> navigateTo<T>(BuildContext context, String route, {Object? arguments}) async {
    if (context.mounted) {
      return Navigator.of(context).pushNamed<T>(route, arguments: arguments);
    }
    return null;
  }

  static Future<T?> replaceWith<T, TO>(BuildContext context, String route, {Object? arguments, TO? result}) async {
    if (context.mounted) {
      return Navigator.of(context).pushReplacementNamed<T, TO>(route, arguments: arguments, result: result);
    }
    return null;
  }

  static Future<T?> replaceUntil<T>(BuildContext context, String route, {Object? arguments}) async {
    if (context.mounted) {
      return Navigator.of(context).pushNamedAndRemoveUntil<T>(route, (Route<dynamic> route) => false, arguments: arguments);
    }
    return null;
  }

  static void pop<T>(BuildContext context, {T? result}) {
    if (context.mounted) {
      Navigator.of(context).pop<T>(result);
    }
  }
}
