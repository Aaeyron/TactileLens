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
  Timer? _progressTimer;

  late final AnimationController _entranceController;
  late final Animation<double> _backgroundOpacity;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _brandingOpacity;
  late final Animation<Offset> _brandingPosition;
  late final Animation<double> _loadingOpacity;
  late final Animation<Offset> _loadingPosition;

  double _progress = SplashScreenStyles.zero;
  bool _isLoaded = false;
  bool _hasCompletedLoading = false;

  @override
  void initState() {
    super.initState();

    _configureAnimations();
    _startLoading();

    unawaited(_entranceController.forward());
  }

  void _configureAnimations() {
    _entranceController = AnimationController(
      vsync: this,
      duration: SplashScreenStyles.entranceAnimationDuration,
    );

    _backgroundOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0, 0.45, curve: SplashScreenStyles.entranceCurve),
    );

    _logoOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(
        0.08,
        0.55,
        curve: SplashScreenStyles.entranceCurve,
      ),
    );

    _logoScale =
        Tween<double>(
          begin: SplashScreenStyles.logoInitialScale,
          end: SplashScreenStyles.fullOpacity,
        ).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(
              0.08,
              0.65,
              curve: SplashScreenStyles.entranceCurve,
            ),
          ),
        );

    _brandingOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(
        0.32,
        0.78,
        curve: SplashScreenStyles.entranceCurve,
      ),
    );

    _brandingPosition =
        Tween<Offset>(
          begin: SplashScreenStyles.brandingBeginOffset,
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(
              0.32,
              0.82,
              curve: SplashScreenStyles.entranceCurve,
            ),
          ),
        );

    _loadingOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.62, 1, curve: SplashScreenStyles.entranceCurve),
    );

    _loadingPosition =
        Tween<Offset>(
          begin: SplashScreenStyles.loadingBeginOffset,
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(
              0.62,
              1,
              curve: SplashScreenStyles.entranceCurve,
            ),
          ),
        );
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _entranceController.dispose();
    super.dispose();
  }

  void _startLoading() {
    final int totalTicks =
        SplashScreenStyles.minimumSplashDuration.inMilliseconds ~/
        SplashScreenStyles.progressInterval.inMilliseconds;

    final double progressPerTick = 1 / totalTicks;

    _progressTimer = Timer.periodic(SplashScreenStyles.progressInterval, (
      Timer timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final double nextProgress = _progress + progressPerTick;

      setState(() {
        _progress = nextProgress.clamp(0, 1);
      });

      if (_progress >= 1) {
        timer.cancel();
        unawaited(_completeLoading());
      }
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
          FadeTransition(
            opacity: _backgroundOpacity,
            child: const _SplashBackground(),
          ),
          SafeArea(
            child: Padding(
              padding: SplashScreenStyles.screenPadding,
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      FadeTransition(
                        opacity: _logoOpacity,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: const _LogoCard(),
                        ),
                      ),
                      const SizedBox(
                        height: SplashScreenStyles.titleTopSpacing,
                      ),
                      FadeTransition(
                        opacity: _brandingOpacity,
                        child: SlideTransition(
                          position: _brandingPosition,
                          child: const _BrandingContent(),
                        ),
                      ),
                      const SizedBox(
                        height: SplashScreenStyles.loadingTopSpacing,
                      ),
                      FadeTransition(
                        opacity: _loadingOpacity,
                        child: SlideTransition(
                          position: _loadingPosition,
                          child: AnimatedSwitcher(
                            duration: SplashScreenStyles.transitionDuration,
                            switchInCurve: SplashScreenStyles.switchCurve,
                            switchOutCurve: SplashScreenStyles.switchCurve,
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                                  final Animation<Offset>
                                  position = Tween<Offset>(
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
                                ? _GetStartedButton(
                                    onPressed: _openAuthentication,
                                  )
                                : _LoadingState(progress: _progress),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: SplashScreenStyles.illustrationLeft,
            bottom: SplashScreenStyles.illustrationBottom,
            child: FadeTransition(
              opacity: _backgroundOpacity,
              child: const _AccessibilityIllustration(),
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
    return const Column(
      children: <Widget>[
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            SplashScreenStyles.appName,
            textAlign: TextAlign.center,
            style: SplashScreenStyles.titleStyle,
          ),
        ),
        SizedBox(height: SplashScreenStyles.taglineTopSpacing),
        Text(
          SplashScreenStyles.tagline,
          textAlign: TextAlign.center,
          style: SplashScreenStyles.taglineStyle,
        ),
        SizedBox(height: SplashScreenStyles.descriptionTopSpacing),
        Text(
          SplashScreenStyles.description,
          textAlign: TextAlign.center,
          style: SplashScreenStyles.descriptionStyle,
        ),
      ],
    );
  }
}

class _LogoCard extends StatelessWidget {
  const _LogoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: SplashScreenStyles.logoSize,
      height: SplashScreenStyles.logoSize,
      decoration: const BoxDecoration(
        gradient: SplashScreenStyles.logoGradient,
        borderRadius: SplashScreenStyles.logoBorderRadius,
        boxShadow: SplashScreenStyles.logoShadow,
      ),
      child: Center(
        child: Image.asset(
          SplashScreenStyles.logoAsset,
          width: SplashScreenStyles.logoImageSize,
          height: SplashScreenStyles.logoImageSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final int activeIndex = (progress * SplashScreenStyles.loadingDotCount)
        .floor()
        .clamp(0, SplashScreenStyles.loadingDotCount - 1)
        .toInt();

    return Column(
      key: const ValueKey<String>('loading'),
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(SplashScreenStyles.loadingDotCount, (
            int index,
          ) {
            final bool isActive = index == activeIndex;
            final bool isComplete = index < activeIndex;

            return AnimatedContainer(
              duration: SplashScreenStyles.transitionDuration,
              curve: SplashScreenStyles.switchCurve,
              width: isActive
                  ? SplashScreenStyles.activeLoadingDotSize
                  : SplashScreenStyles.loadingDotSize,
              height: isActive
                  ? SplashScreenStyles.activeLoadingDotSize
                  : SplashScreenStyles.loadingDotSize,
              margin: const EdgeInsets.symmetric(
                horizontal: SplashScreenStyles.loadingDotSpacing / 2,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive || isComplete
                    ? SplashScreenStyles.primaryColor
                    : SplashScreenStyles.inactiveDotColor,
                boxShadow: isActive
                    ? const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x331746C7),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            );
          }, growable: false),
        ),
        const SizedBox(height: SplashScreenStyles.messageTopSpacing),
        const Text(
          SplashScreenStyles.loadingMessage,
          textAlign: TextAlign.center,
          style: SplashScreenStyles.loadingMessageStyle,
        ),
      ],
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

class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned(
          top: SplashScreenStyles.topCircleTop,
          left: SplashScreenStyles.topCircleLeft,
          child: Container(
            width: SplashScreenStyles.topCircleSize,
            height: SplashScreenStyles.topCircleSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: SplashScreenStyles.topDecorationColor,
            ),
          ),
        ),
        Positioned(
          right: SplashScreenStyles.bottomCircleRight,
          bottom: SplashScreenStyles.bottomCircleBottom,
          child: Container(
            width: SplashScreenStyles.bottomCircleSize,
            height: SplashScreenStyles.bottomCircleSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: SplashScreenStyles.bottomDecorationColor,
            ),
          ),
        ),
        const Positioned(
          top: SplashScreenStyles.leftBrailleTop,
          left: SplashScreenStyles.leftBrailleLeft,
          child: _BrailleDecoration(),
        ),
        const Positioned(
          top: SplashScreenStyles.rightBrailleTop,
          right: SplashScreenStyles.rightBrailleRight,
          child: _BrailleDecoration(),
        ),
        const Positioned(
          right: SplashScreenStyles.bottomBrailleRight,
          bottom: SplashScreenStyles.bottomBrailleBottom,
          child: _BrailleDecoration(),
        ),
      ],
    );
  }
}

class _BrailleDecoration extends StatelessWidget {
  const _BrailleDecoration();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: SplashScreenStyles.decorationOpacity,
      child: SizedBox(
        width: 52,
        child: Wrap(
          spacing: 14,
          runSpacing: 14,
          children: List<Widget>.generate(
            6,
            (_) => Container(
              width: SplashScreenStyles.decorationDotSize,
              height: SplashScreenStyles.decorationDotSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: SplashScreenStyles.accentColor,
              ),
            ),
            growable: false,
          ),
        ),
      ),
    );
  }
}

class _AccessibilityIllustration extends StatelessWidget {
  const _AccessibilityIllustration();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: SplashScreenStyles.illustrationOpacity,
      child: SizedBox(
        width: SplashScreenStyles.bottomIllustrationSize,
        height: SplashScreenStyles.bottomIllustrationSize,
        child: Stack(
          alignment: Alignment.center,
          children: const <Widget>[
            Positioned(
              left: 0,
              bottom: 4,
              child: Icon(
                Icons.menu_book_rounded,
                size: SplashScreenStyles.bookIconSize,
                color: SplashScreenStyles.accentColor,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Icon(
                Icons.manage_search_rounded,
                size: SplashScreenStyles.searchIconSize,
                color: SplashScreenStyles.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
