import 'package:flutter/material.dart';

class AppRouter {
  const AppRouter._();

  static Future<T?> push<T>(
    BuildContext context,
    Widget page, {
    String? routeName,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (_) => page,
        settings: routeName != null ? RouteSettings(name: routeName) : null,
      ),
    );
  }

  static Future<T?> pushReplacement<T>(
    BuildContext context,
    Widget page, {
    String? routeName,
  }) {
    return Navigator.of(context).pushReplacement<T, T>(
      MaterialPageRoute(
        builder: (_) => page,
        settings: routeName != null ? RouteSettings(name: routeName) : null,
      ),
    );
  }

  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop<T>(result);
  }
}
