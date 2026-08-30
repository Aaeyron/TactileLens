import 'package:flutter/material.dart';

import '../../styles/screens/auth/auth_screen_styles.dart';
import '../../utils/session_manager.dart';
import '../main/main_screen.dart';
import 'guest_setup_screen.dart';
import 'signin_screen.dart';
import 'signup_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isRestoringGuest = false;

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (BuildContext context) => screen));
  }

  Future<void> _continueAsGuest() async {
    if (_isRestoringGuest) {
      return;
    }

    setState(() {
      _isRestoringGuest = true;
    });

    try {
      final bool restoredGuest = await SessionManager.activateSavedGuest();

      if (!mounted) {
        return;
      }

      if (restoredGuest) {
        Navigator.of(context).pushAndRemoveUntil<void>(
          MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return const MainScreen();
            },
          ),
          (Route<dynamic> route) => false,
        );

        return;
      }

      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return const GuestSetupScreen();
          },
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to restore Guest Mode: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Unable to continue as guest. Please try again.'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isRestoringGuest = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthStyles.backgroundColor,
      body: Stack(
        children: <Widget>[
          const Positioned(
            top: AuthStyles.topDecorationOffset,
            left: AuthStyles.topDecorationOffset,
            child: _BackgroundCircle(size: AuthStyles.topDecorationSize),
          ),
          const Positioned(
            right: AuthStyles.bottomDecorationOffset,
            bottom: AuthStyles.bottomDecorationOffset,
            child: _BackgroundCircle(size: AuthStyles.bottomDecorationSize),
          ),
          const Positioned(
            top: AuthStyles.topDotDecorationTop,
            right: AuthStyles.dotDecorationSide,
            child: _BrailleDotDecoration(),
          ),
          const Positioned(
            top: AuthStyles.middleDotDecorationTop,
            left: AuthStyles.dotDecorationSide,
            child: _BrailleDotDecoration(),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: AuthStyles.pagePadding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight -
                          AuthStyles.pagePadding.vertical,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const SizedBox(height: AuthStyles.topSpacing),
                        _buildLogo(),
                        const SizedBox(height: AuthStyles.logoBottomSpacing),
                        const Text(
                          AuthStyles.welcomeText,
                          textAlign: TextAlign.center,
                          style: AuthStyles.welcomeStyle,
                        ),
                        _buildAppName(),
                        const SizedBox(
                          height: AuthStyles.titleIndicatorSpacing,
                        ),
                        const _TitleIndicator(),
                        const SizedBox(height: AuthStyles.taglineTopSpacing),
                        const Text(
                          AuthStyles.tagline,
                          textAlign: TextAlign.center,
                          style: AuthStyles.taglineStyle,
                        ),
                        const SizedBox(
                          height: AuthStyles.descriptionTopSpacing,
                        ),
                        const Text(
                          AuthStyles.description,
                          textAlign: TextAlign.center,
                          style: AuthStyles.descriptionStyle,
                        ),
                        const SizedBox(height: AuthStyles.actionsTopSpacing),
                        _buildSignInButton(context),
                        const SizedBox(height: AuthStyles.buttonSpacing),
                        _buildSignUpButton(context),
                        const SizedBox(
                          height: AuthStyles.dividerVerticalSpacing,
                        ),
                        const _OrDivider(),
                        const SizedBox(
                          height: AuthStyles.dividerVerticalSpacing,
                        ),
                        _buildGuestButton(context),
                        const SizedBox(height: AuthStyles.featuresTopSpacing),
                        const _FeatureSection(),
                        const SizedBox(height: AuthStyles.bottomSpacing),
                        const _PageIndicator(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: AuthStyles.logoContainerSize,
      height: AuthStyles.logoContainerSize,
      padding: AuthStyles.logoPadding,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: AuthStyles.logoGradient,
        borderRadius: AuthStyles.logoRadius,
        boxShadow: AuthStyles.logoShadow,
      ),
      child: Image.asset(
        AuthStyles.logoAsset,
        fit: BoxFit.contain,
        semanticLabel: AuthStyles.logoSemanticLabel,
      ),
    );
  }

  Widget _buildAppName() {
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          const TextSpan(
            text: AuthStyles.appNameFirstPart,
            style: AuthStyles.appNameDarkStyle,
          ),
          TextSpan(
            text: AuthStyles.appNameSecondPart,
            style: AuthStyles.appNameBlueStyle,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSignInButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AuthStyles.buttonHeight,
      child: ElevatedButton(
        onPressed: () {
          _openScreen(context, const SignInScreen());
        },
        style: AuthStyles.signInButtonStyle,
        child: const Row(
          children: <Widget>[
            Icon(AuthStyles.signInIcon, size: AuthStyles.buttonIconSize),
            Expanded(
              child: Text(
                AuthStyles.signInLabel,
                textAlign: TextAlign.center,
                style: AuthStyles.primaryButtonTextStyle,
              ),
            ),
            Icon(AuthStyles.forwardIcon, size: AuthStyles.forwardIconSize),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AuthStyles.buttonHeight,
      child: OutlinedButton(
        onPressed: () {
          _openScreen(context, const SignUpScreen());
        },
        style: AuthStyles.signUpButtonStyle,
        child: const Row(
          children: <Widget>[
            Icon(AuthStyles.signUpIcon, size: AuthStyles.buttonIconSize),
            Expanded(
              child: Text(
                AuthStyles.signUpLabel,
                textAlign: TextAlign.center,
                style: AuthStyles.secondaryButtonTextStyle,
              ),
            ),
            Icon(
              AuthStyles.forwardIcon,
              size: AuthStyles.forwardIconSize,
              color: AuthStyles.forwardIconColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AuthStyles.buttonHeight,
      child: OutlinedButton(
        onPressed: _isRestoringGuest ? null : _continueAsGuest,
        style: AuthStyles.guestButtonStyle,
        child: _isRestoringGuest
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AuthStyles.primaryColor,
                ),
              )
            : const Row(
                children: <Widget>[
                  Icon(AuthStyles.guestIcon, size: AuthStyles.buttonIconSize),
                  Expanded(
                    child: Text(
                      AuthStyles.guestLabel,
                      textAlign: TextAlign.center,
                      style: AuthStyles.guestButtonTextStyle,
                    ),
                  ),
                  Icon(
                    AuthStyles.forwardIcon,
                    size: AuthStyles.forwardIconSize,
                    color: AuthStyles.forwardIconColor,
                  ),
                ],
              ),
      ),
    );
  }
}

class _BackgroundCircle extends StatelessWidget {
  const _BackgroundCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: AuthStyles.backgroundDecorationGradient,
        ),
      ),
    );
  }
}

class _BrailleDotDecoration extends StatelessWidget {
  const _BrailleDotDecoration();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Wrap(
        direction: Axis.vertical,
        spacing: AuthStyles.decorationDotSpacing,
        runSpacing: AuthStyles.decorationDotSpacing,
        children: List<Widget>.generate(AuthStyles.decorationDotCount, (
          int index,
        ) {
          return const DecoratedBox(
            decoration: BoxDecoration(
              color: AuthStyles.decorationDotColor,
              shape: BoxShape.circle,
              boxShadow: AuthStyles.decorationDotShadow,
            ),
            child: SizedBox.square(dimension: AuthStyles.decorationDotSize),
          );
        }, growable: false),
      ),
    );
  }
}

class _TitleIndicator extends StatelessWidget {
  const _TitleIndicator();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: AuthStyles.indicatorLineWidth,
          child: Divider(
            height: AuthStyles.indicatorHeight,
            thickness: AuthStyles.indicatorThickness,
            color: AuthStyles.primaryColor,
          ),
        ),
        SizedBox(width: AuthStyles.indicatorSpacing),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AuthStyles.primaryColor,
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(dimension: AuthStyles.indicatorDotSize),
        ),
        SizedBox(width: AuthStyles.indicatorSpacing),
        SizedBox(
          width: AuthStyles.indicatorLineWidth,
          child: Divider(
            height: AuthStyles.indicatorHeight,
            thickness: AuthStyles.indicatorThickness,
            color: AuthStyles.primaryColor,
          ),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        Expanded(
          child: Divider(
            color: AuthStyles.dividerColor,
            thickness: AuthStyles.dividerThickness,
          ),
        ),
        Padding(
          padding: AuthStyles.orLabelPadding,
          child: Text(AuthStyles.orLabel, style: AuthStyles.orLabelStyle),
        ),
        Expanded(
          child: Divider(
            color: AuthStyles.dividerColor,
            thickness: AuthStyles.dividerThickness,
          ),
        ),
      ],
    );
  }
}

class _FeatureSection extends StatelessWidget {
  const _FeatureSection();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _FeatureItem(
            icon: AuthStyles.scanningIcon,
            title: AuthStyles.scanningTitle,
            description: AuthStyles.scanningDescription,
          ),
        ),
        _FeatureDivider(),
        Expanded(
          child: _FeatureItem(
            icon: AuthStyles.translationIcon,
            title: AuthStyles.translationTitle,
            description: AuthStyles.translationDescription,
          ),
        ),
        _FeatureDivider(),
        Expanded(
          child: _FeatureItem(
            icon: AuthStyles.accessibilityIcon,
            title: AuthStyles.accessibilityTitle,
            description: AuthStyles.accessibilityDescription,
          ),
        ),
      ],
    );
  }
}

class _FeatureDivider extends StatelessWidget {
  const _FeatureDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AuthStyles.featureDividerWidth,
      height: AuthStyles.featureDividerHeight,
      margin: AuthStyles.featureDividerMargin,
      color: AuthStyles.featureDividerColor,
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: AuthStyles.featureIconContainerSize,
          height: AuthStyles.featureIconContainerSize,
          decoration: const BoxDecoration(
            color: AuthStyles.featureIconBackgroundColor,
            borderRadius: AuthStyles.featureIconRadius,
            boxShadow: AuthStyles.featureIconShadow,
          ),
          child: Icon(
            icon,
            size: AuthStyles.featureIconSize,
            color: AuthStyles.primaryColor,
          ),
        ),
        const SizedBox(height: AuthStyles.featureTitleTopSpacing),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AuthStyles.featureTitleStyle,
        ),
        const SizedBox(height: AuthStyles.featureDescriptionTopSpacing),
        Text(
          description,
          textAlign: TextAlign.center,
          style: AuthStyles.featureDescriptionStyle,
        ),
      ],
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _IndicatorDot(color: AuthStyles.primaryColor),
        SizedBox(width: AuthStyles.pageIndicatorSpacing),
        _IndicatorDot(color: AuthStyles.inactiveIndicatorColor),
        SizedBox(width: AuthStyles.pageIndicatorSpacing),
        _IndicatorDot(color: AuthStyles.inactiveIndicatorColor),
      ],
    );
  }
}

class _IndicatorDot extends StatelessWidget {
  const _IndicatorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: const SizedBox.square(dimension: AuthStyles.pageIndicatorSize),
    );
  }
}
