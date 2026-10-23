import 'package:admivida/common/utils/globals.dart';
import 'package:flutter/material.dart';

class NavigationService {
  NavigationService._();

  static BuildContext? get currentContext => navigatorKey.currentContext;

  static Future<T?> navigateTo<T>(BuildContext? context, String route, {Object? arguments}) async {
    if (context != null && context.mounted) {
      return Navigator.of(context).pushNamed<T>(route, arguments: arguments);
    }
    return navigatorKey.currentState?.pushNamed<T>(route, arguments: arguments);
  }

  static Future<T?> replaceWith<T, TO>(BuildContext? context, String route, {Object? arguments, TO? result}) async {
    if (context != null && context.mounted) {
      return Navigator.of(context).pushReplacementNamed<T, TO>(route, arguments: arguments, result: result);
    }
    return navigatorKey.currentState?.pushReplacementNamed<T, TO>(route, arguments: arguments, result: result);
  }

  static Future<T?> replaceUntil<T>(BuildContext? context, String route, {Object? arguments, RoutePredicate? predicate}) async {
    final routePredicate = predicate ?? ((Route<dynamic> route) => false);
    if (context != null && context.mounted) {
      return Navigator.of(context).pushNamedAndRemoveUntil<T>(route, routePredicate, arguments: arguments);
    }
    return navigatorKey.currentState?.pushNamedAndRemoveUntil<T>(route, routePredicate, arguments: arguments);
  }

  static void pop<T>([BuildContext? context, T? result, bool rootNavigator = false]) {
    if (context != null && context.mounted) {
      Navigator.of(context, rootNavigator: rootNavigator).pop<T>(result);
    } else {
      navigatorKey.currentState?.pop<T>(result);
    }
  }

  static Future<bool> maybePop<T>([BuildContext? context, T? result]) async {
    if (context != null && context.mounted) {
      return Navigator.of(context).maybePop<T>(result);
    }
    return (await navigatorKey.currentState?.maybePop<T>(result)) ?? false;
  }

  static void popUntil(BuildContext? context, RoutePredicate predicate) {
    if (context != null && context.mounted) {
      Navigator.of(context).popUntil(predicate);
    } else {
      navigatorKey.currentState?.popUntil(predicate);
    }
  }

  static bool canPop([BuildContext? context]) {
    if (context != null && context.mounted) {
      return Navigator.of(context).canPop();
    }
    return navigatorKey.currentState?.canPop() ?? false;
  }

  static Future<T?> push<T>(BuildContext? context, Route<T> route) async {
    if (context != null && context.mounted) {
      return Navigator.of(context).push<T>(route);
    }
    return navigatorKey.currentState?.push<T>(route);
  }
}
