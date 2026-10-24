import 'package:flutter/material.dart';

/// Screen-to-screen transition used on every platform: the new screen
/// slides in from the right, and slides back out to the right on Back.
/// No fade, no scale. With reduced motion the screen switches instantly.
///
/// Set once in the app theme (pageTransitionsTheme), so every
/// MaterialPageRoute uses it.
class SlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const SlidePageTransitionsBuilder();

  static const Offset _offScreenRight = Offset(1, 0);

  static const Curve _curve = Curves.easeOutCubic;
  static const Curve _reverseCurve = Curves.easeInCubic;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    return SlideTransition(
      position: Tween<Offset>(begin: _offScreenRight, end: Offset.zero).animate(
        CurvedAnimation(
          parent: animation,
          curve: _curve,
          reverseCurve: _reverseCurve,
        ),
      ),
      child: child,
    );
  }
}

/// The same slide for every platform the app can run on.
const PageTransitionsTheme slidePageTransitionsTheme = PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    TargetPlatform.android: SlidePageTransitionsBuilder(),
    TargetPlatform.iOS: SlidePageTransitionsBuilder(),
    TargetPlatform.fuchsia: SlidePageTransitionsBuilder(),
    TargetPlatform.linux: SlidePageTransitionsBuilder(),
    TargetPlatform.macOS: SlidePageTransitionsBuilder(),
    TargetPlatform.windows: SlidePageTransitionsBuilder(),
  },
);
