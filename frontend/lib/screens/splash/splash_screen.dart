import 'dart:async';

import 'package:flutter/material.dart';

import '../../styles/screens/splash/splash_screen_styles.dart';
import '../../utils/session_manager.dart';
import '../auth/auth_screen.dart';
import '../main/main_screen.dart';

/// Where the app goes after the splash.
enum SplashDestination { main, auth }

/// Shows the logo and "TactileLens" while the saved session is read, then
/// moves on by itself: guest or signed in -> MainScreen, otherwise
/// AuthScreen. Reading the session is local only, so it works offline.
///
/// The splash stays at least [minimumDuration] and at most
/// [maximumDuration]. If reading the session fails or is still running at
/// [maximumDuration], the app goes to AuthScreen: never stuck here.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.loadDestination = loadSavedDestination,
    this.minimumDuration = SplashScreenStyles.minimumDuration,
    this.maximumDuration = SplashScreenStyles.maximumDuration,
    this.buildDestination = buildDestinationScreen,
  });

  @visibleForTesting
  final Future<SplashDestination> Function() loadDestination;

  @visibleForTesting
  final Duration minimumDuration;

  @visibleForTesting
  final Duration maximumDuration;

  @visibleForTesting
  final Widget Function(SplashDestination destination) buildDestination;

  /// Same routing as the former "Get Started" flow.
  static Future<SplashDestination> loadSavedDestination() async {
    if (await SessionManager.isGuest()) {
      return SplashDestination.main;
    }

    if (await SessionManager.isLoggedIn()) {
      return SplashDestination.main;
    }

    return SplashDestination.auth;
  }

  static Widget buildDestinationScreen(SplashDestination destination) {
    return switch (destination) {
      SplashDestination.main => const MainScreen(),
      SplashDestination.auth => const AuthScreen(),
    };
  }

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    unawaited(_loadAndContinue());
  }

  Future<void> _loadAndContinue() async {
    SplashDestination destination = SplashDestination.auth;

    try {
      // Future.wait waits for both, so even a failed load keeps the
      // splash up for the minimum time.
      final List<Object> results = await Future.wait<Object>(<Future<Object>>[
        widget.loadDestination(),
        Future<Object>.delayed(widget.minimumDuration, () => true),
      ]).timeout(widget.maximumDuration);

      destination = results.first as SplashDestination;
    } on TimeoutException {
      debugPrint('Splash: loading took too long; opening sign in.');
    } catch (error) {
      debugPrint('Splash: loading failed ($error); opening sign in.');
    }

    _continueTo(destination);
  }

  void _continueTo(SplashDestination destination) {
    if (!mounted || _hasNavigated) {
      return;
    }

    _hasNavigated = true;

    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => widget.buildDestination(destination),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: SplashScreenStyles.backgroundColor,
      body: Center(
        child: Padding(
          padding: SplashScreenStyles.screenPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // The title below already says "TactileLens"; TalkBack reads
              // it once.
              ExcludeSemantics(child: _Logo()),
              SizedBox(height: SplashScreenStyles.titleTopSpacing),
              Text(
                SplashScreenStyles.appName,
                textAlign: TextAlign.center,
                style: SplashScreenStyles.titleStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: SplashScreenStyles.logoSize,
      height: SplashScreenStyles.logoSize,
      decoration: const BoxDecoration(
        borderRadius: SplashScreenStyles.logoBorderRadius,
        boxShadow: SplashScreenStyles.logoShadow,
      ),
      child: ClipRRect(
        borderRadius: SplashScreenStyles.logoBorderRadius,
        child: Image.asset(SplashScreenStyles.logoAsset, fit: BoxFit.cover),
      ),
    );
  }
}
