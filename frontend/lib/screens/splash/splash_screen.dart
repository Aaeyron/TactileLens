import 'dart:async';

import 'package:flutter/material.dart';

import '../../styles/screens/splash/splash_screen_styles.dart';
import '../../utils/session_manager.dart';
import '../auth/auth_screen.dart';
import '../main/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _loadingTimer;

  late final AnimationController _entranceController;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _brandingOpacity;
  late final Animation<Offset> _brandingPosition;

  bool _isLoaded = false;
  bool _hasCompletedLoading = false;

  @override
  void initState() {
    super.initState();

    _configureAnimations();
    _startLoading();

    unawaited(_entranceController.forward());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _entranceController.value = 1.0;
    }
  }

  void _configureAnimations() {
    _entranceController = AnimationController(
      vsync: this,
      duration: SplashScreenStyles.entranceAnimationDuration,
    );

    _logoOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(
        0.05,
        0.55,
        curve: SplashScreenStyles.entranceCurve,
      ),
    );

    _logoScale = Tween<double>(
      begin: SplashScreenStyles.logoInitialScale,
      end: SplashScreenStyles.fullOpacity,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(
          0.05,
          0.65,
          curve: SplashScreenStyles.entranceCurve,
        ),
      ),
    );

    _brandingOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(
        0.30,
        0.85,
        curve: SplashScreenStyles.entranceCurve,
      ),
    );

    _brandingPosition = Tween<Offset>(
      begin: SplashScreenStyles.brandingBeginOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(
          0.30,
          0.85,
          curve: SplashScreenStyles.entranceCurve,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _entranceController.dispose();
    super.dispose();
  }

  void _startLoading() {
    // A single timer: the splash shows no progress bar, so ticking
    // setState calls would only rebuild the screen without changes.
    _loadingTimer = Timer(SplashScreenStyles.minimumSplashDuration, () {
      if (!mounted) {
        return;
      }

      unawaited(_completeLoading());
    });
  }

  Future<void> _completeLoading() async {
    if (_hasCompletedLoading) {
      return;
    }

    _hasCompletedLoading = true;

    final bool isGuest = await SessionManager.isGuest();

    if (!mounted) {
      return;
    }

    if (isGuest) {
      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const MainScreen(),
        ),
      );
      return;
    }

    final bool isLoggedIn = await SessionManager.isLoggedIn();

    if (!mounted) {
      return;
    }

    if (isLoggedIn) {
      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const MainScreen(),
        ),
      );
      return;
    }

    setState(() {
      _isLoaded = true;
    });
  }

  void _openAuthentication() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SplashScreenStyles.backgroundColor,
      body: Stack(
        children: <Widget>[
          Center(
            child: Padding(
              padding: SplashScreenStyles.screenPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  FadeTransition(
                    opacity: _logoOpacity,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: const _LogoCard(),
                    ),
                  ),
                  const SizedBox(height: SplashScreenStyles.titleTopSpacing),
                  FadeTransition(
                    opacity: _brandingOpacity,
                    child: SlideTransition(
                      position: _brandingPosition,
                      child: const _BrandingContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: SplashScreenStyles.screenHorizontalPadding,
                  right: SplashScreenStyles.screenHorizontalPadding,
                  bottom: SplashScreenStyles.bottomPadding,
                ),
                child: AnimatedSwitcher(
                  duration: SplashScreenStyles.transitionDuration,
                  switchInCurve: SplashScreenStyles.switchCurve,
                  switchOutCurve: SplashScreenStyles.switchCurve,
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    final Animation<Offset> position = Tween<Offset>(
                      begin: SplashScreenStyles.switchBeginOffset,
                      end: Offset.zero,
                    ).animate(animation);

                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: position,
                        child: child,
                      ),
                    );
                  },
                  child: _isLoaded
                      ? _GetStartedButton(onPressed: _openAuthentication)
                      : const SizedBox(height: SplashScreenStyles.buttonHeight),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandingContent extends StatelessWidget {
  const _BrandingContent();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: SplashScreenStyles.appName,
      child: const Text(
        SplashScreenStyles.appName,
        textAlign: TextAlign.center,
        style: SplashScreenStyles.titleStyle,
      ),
    );
  }
}

class _LogoCard extends StatelessWidget {
  const _LogoCard();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'TactileLens app logo',
      image: true,
      child: Container(
        width: SplashScreenStyles.logoSize,
        height: SplashScreenStyles.logoSize,
        decoration: const BoxDecoration(
          borderRadius: SplashScreenStyles.logoBorderRadius,
          boxShadow: SplashScreenStyles.logoShadow,
        ),
        child: ClipRRect(
          borderRadius: SplashScreenStyles.logoBorderRadius,
          child: Image.asset(
            SplashScreenStyles.logoAsset,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _GetStartedButton extends StatelessWidget {
  const _GetStartedButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey<String>('get-started'),
      width: double.infinity,
      height: SplashScreenStyles.buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: SplashScreenStyles.getStartedButtonStyle,
        child: const Text(
          SplashScreenStyles.getStartedLabel,
          style: SplashScreenStyles.buttonTextStyle,
        ),
      ),
    );
  }
}
