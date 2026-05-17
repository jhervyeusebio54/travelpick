import 'package:flutter/material.dart';

class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({required Widget child})
    : super(
        transitionDuration: const Duration(milliseconds: 360),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.08, 0.02),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
      );
}

Future<T?> pushAppPage<T>(BuildContext context, Widget child) {
  return Navigator.of(context).push<T>(AppPageRoute(child: child));
}

Future<T?> replaceWithAppPage<T>(BuildContext context, Widget child) {
  return Navigator.of(
    context,
  ).pushReplacement<T, T>(AppPageRoute(child: child));
}
