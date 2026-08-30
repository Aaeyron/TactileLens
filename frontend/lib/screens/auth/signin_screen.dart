import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/auth/auth_service.dart';
import '../../services/auth/google_sign_in_service.dart';
import '../../styles/screens/auth/signin_screen_styles.dart';
import '../../utils/session_manager.dart';
import '../main/main_screen.dart';
import 'guest_setup_screen.dart';
import 'signup_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() {
    return _SignInScreenState();
  }
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  bool isPasswordVisible = false;

  bool _isSigningIn = false;
  bool _isGoogleSigningIn = false;
  bool _isRestoringGuest = false;

  bool get _isBusy {
    return _isSigningIn || _isGoogleSigningIn || _isRestoringGuest;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (_isBusy) {
      return;
    }

    setState(() {
      _isGoogleSigningIn = true;
    });

    try {
      final String idToken = await GoogleSignInService.authenticate();

      final response = await AuthService.loginWithGoogle(idToken: idToken);

      debugPrint(
        'Google login response: '
        'status=${response.statusCode}, '
        'body=${response.body}',
      );

      final Map<String, dynamic> responseData = _decodeResponse(response.body);

      if (response.statusCode != 200) {
        throw SignInException(
          _readServerMessage(responseData) ?? SignInStyles.defaultSignInError,
        );
      }

      final dynamic rawUser = responseData['user'];
      final dynamic rawToken = responseData['token'];

      if (rawUser is! Map) {
        throw const SignInException(SignInStyles.invalidUserMessage);
      }

      if (rawToken is! String || rawToken.trim().isEmpty) {
        throw const SignInException(SignInStyles.missingTokenMessage);
      }

      final Map<String, dynamic> user = Map<String, dynamic>.from(rawUser);

      final dynamic rawUserId = user['id'];

      final int? userId = rawUserId is num
          ? rawUserId.toInt()
          : int.tryParse(rawUserId?.toString() ?? '');

      if (userId == null) {
        throw const SignInException(SignInStyles.invalidUserIdMessage);
      }

      final String firstName = _readRequiredString(user, 'first_name');

      final String lastName = _readRequiredString(user, 'last_name');

      final String userEmail = _readRequiredString(user, 'email');

      final String role = _readRequiredString(user, 'role');

      await SessionManager.saveAccessToken(rawToken.trim());

      try {
        await SessionManager.saveUser(
          id: userId,
          firstName: firstName,
          lastName: lastName,
          email: userEmail,
          role: role,
        );
      } catch (_) {
        await SessionManager.logout();
        rethrow;
      }

      if (!mounted) {
        return;
      }

      _showMessage(SignInStyles.loginSuccessMessage);

      Navigator.of(context).pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return const MainScreen();
          },
        ),
        (Route<dynamic> route) => false,
      );
    } on GoogleSignInServiceException catch (error) {
      debugPrint(
        'Google sign-in service error: '
        'code=${error.code}, '
        'message=${error.message}, '
        'description=${error.description}, '
        'details=${error.details}',
      );

      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } on SignInException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } on FormatException {
      if (!mounted) {
        return;
      }

      _showMessage(SignInStyles.invalidResponseMessage);
    } catch (error, stackTrace) {
      debugPrint('Google sign-in failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      _showMessage(SignInStyles.connectionErrorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleSigningIn = false;
        });
      }
    }
  }

  Future<void> _signIn() async {
    if (_isBusy) {
      return;
    }

    final String email = emailController.text.trim();
    final String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage(SignInStyles.emptyFieldsMessage);
      return;
    }

    setState(() {
      _isSigningIn = true;
    });

    try {
      final response = await AuthService.loginUser(
        email: email,
        password: password,
      );

      final Map<String, dynamic> responseData = _decodeResponse(response.body);

      if (response.statusCode != 200) {
        final String? serverCode = _readServerCode(responseData);

        if (serverCode == 'google_sign_in_required') {
          if (!mounted) {
            return;
          }

          setState(() {
            _isSigningIn = false;
          });

          final bool continueWithGoogle =
              await _showGoogleSignInRequiredDialog();

          if (continueWithGoogle && mounted) {
            await _signInWithGoogle();
          }

          return;
        }

        throw SignInException(
          _readServerMessage(responseData) ?? SignInStyles.defaultSignInError,
        );
      }

      final dynamic rawUser = responseData['user'];
      final dynamic rawToken = responseData['token'];

      if (rawUser is! Map) {
        throw const SignInException(SignInStyles.invalidUserMessage);
      }

      if (rawToken is! String || rawToken.trim().isEmpty) {
        throw const SignInException(SignInStyles.missingTokenMessage);
      }

      final Map<String, dynamic> user = Map<String, dynamic>.from(rawUser);

      final dynamic rawUserId = user['id'];

      if (rawUserId is! num) {
        throw const SignInException(SignInStyles.invalidUserIdMessage);
      }

      final String firstName = _readRequiredString(user, 'first_name');

      final String lastName = _readRequiredString(user, 'last_name');

      final String userEmail = _readRequiredString(user, 'email');

      final String role = _readRequiredString(user, 'role');

      await SessionManager.saveAccessToken(rawToken);

      try {
        await SessionManager.saveUser(
          id: rawUserId.toInt(),
          firstName: firstName,
          lastName: lastName,
          email: userEmail,
          role: role,
        );
      } catch (_) {
        await SessionManager.logout();
        rethrow;
      }

      if (!mounted) {
        return;
      }

      _showMessage(SignInStyles.loginSuccessMessage);

      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return const MainScreen();
          },
        ),
      );
    } on SignInException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } on FormatException {
      if (!mounted) {
        return;
      }

      _showMessage(SignInStyles.invalidResponseMessage);
    } catch (error, stackTrace) {
      debugPrint('Sign-in failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      _showMessage(SignInStyles.connectionErrorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  Map<String, dynamic> _decodeResponse(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final dynamic decoded = jsonDecode(responseBody);

    if (decoded is! Map) {
      throw const FormatException(SignInStyles.invalidResponseMessage);
    }

    return Map<String, dynamic>.from(decoded);
  }

  String _readRequiredString(Map<String, dynamic> source, String key) {
    final dynamic value = source[key];

    if (value is! String || value.trim().isEmpty) {
      throw const SignInException(SignInStyles.incompleteUserMessage);
    }

    return value.trim();
  }

  String? _readServerMessage(Map<String, dynamic> responseData) {
    final dynamic message = responseData['message'];

    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    return null;
  }

  String? _readServerCode(Map<String, dynamic> responseData) {
    final dynamic code = responseData['code'];

    if (code is String && code.trim().isNotEmpty) {
      return code.trim();
    }

    return null;
  }

  Future<bool> _showGoogleSignInRequiredDialog() async {
    if (!mounted) {
      return false;
    }

    final bool? shouldContinue = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: SignInStyles.surfaceColor,
          shape: const RoundedRectangleBorder(
            borderRadius: SignInStyles.accountDialogRadius,
          ),
          titlePadding: SignInStyles.accountDialogTitlePadding,
          contentPadding: SignInStyles.accountDialogContentPadding,
          actionsPadding: SignInStyles.accountDialogActionsPadding,
          title: Row(
            children: <Widget>[
              Container(
                width: SignInStyles.accountDialogIconContainerSize,
                height: SignInStyles.accountDialogIconContainerSize,
                decoration: const BoxDecoration(
                  color: SignInStyles.accountDialogIconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  SignInStyles.googleAccountIcon,
                  color: SignInStyles.brightPrimaryColor,
                  size: SignInStyles.accountDialogIconSize,
                ),
              ),
              const SizedBox(width: SignInStyles.accountDialogIconSpacing),
              const Expanded(
                child: Text(
                  SignInStyles.googleAccountDialogTitle,
                  style: SignInStyles.accountDialogTitleStyle,
                ),
              ),
            ],
          ),
          content: const Text(
            SignInStyles.googleAccountDialogMessage,
            style: SignInStyles.accountDialogMessageStyle,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              style: SignInStyles.accountDialogCancelButtonStyle,
              child: const Text(SignInStyles.cancelLabel),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: SignInStyles.accountDialogGoogleButtonStyle,
              icon: const Text(
                SignInStyles.googleIconLetter,
                style: SignInStyles.accountDialogGoogleIconStyle,
              ),
              label: const Text(SignInStyles.continueWithGoogleLabel),
            ),
          ],
        );
      },
    );

    return shouldContinue ?? false;
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: SignInStyles.snackBarDuration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: SignInStyles.primaryColor,
          margin: SignInStyles.snackBarMargin,
          shape: const RoundedRectangleBorder(
            borderRadius: SignInStyles.snackBarRadius,
          ),
          content: Text(message, style: SignInStyles.snackBarTextStyle),
        ),
      );
  }

  void _openSignUp() {
    if (_isSigningIn) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const SignUpScreen();
        },
      ),
    );
  }

  Future<void> _continueAsGuest() async {
    if (_isBusy) {
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

      _showMessage('Unable to continue as guest. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isRestoringGuest = false;
        });
      }
    }
  }

  void _togglePasswordVisibility() {
    if (_isSigningIn) {
      return;
    }

    setState(() {
      isPasswordVisible = !isPasswordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SignInStyles.backgroundColor,
      body: Stack(
        children: <Widget>[
          const Positioned(
            top: SignInStyles.topDecorationOffset,
            right: SignInStyles.topDecorationOffset,
            child: _BackgroundCircle(size: SignInStyles.topDecorationSize),
          ),
          const Positioned(
            bottom: SignInStyles.bottomDecorationOffset,
            left: SignInStyles.bottomDecorationOffset,
            child: _BackgroundCircle(size: SignInStyles.bottomDecorationSize),
          ),
          const Positioned(
            top: SignInStyles.leftDotsTop,
            left: SignInStyles.dotsSideOffset,
            child: _BrailleDots(),
          ),
          const Positioned(
            top: SignInStyles.rightDotsTop,
            right: SignInStyles.dotsSideOffset,
            child: _BrailleDots(),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: SignInStyles.pagePadding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight -
                          SignInStyles.pagePadding.vertical,
                    ),
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _buildBackButton(context),
                          const SizedBox(height: SignInStyles.logoTopSpacing),
                          _buildLogo(),
                          const SizedBox(
                            height: SignInStyles.logoBottomSpacing,
                          ),
                          const Text(
                            SignInStyles.title,
                            textAlign: TextAlign.center,
                            style: SignInStyles.titleStyle,
                          ),
                          const SizedBox(
                            height: SignInStyles.descriptionSpacing,
                          ),
                          _buildDescription(),
                          const SizedBox(height: SignInStyles.formTopSpacing),
                          _buildEmailField(),
                          const SizedBox(height: SignInStyles.fieldSpacing),
                          _buildPasswordField(),
                          _buildForgotPasswordButton(),
                          const SizedBox(height: SignInStyles.signInTopSpacing),
                          _buildSignInButton(),
                          const SizedBox(height: SignInStyles.dividerSpacing),
                          const _OrDivider(),
                          const SizedBox(height: SignInStyles.dividerSpacing),
                          _buildGoogleButton(),
                          const SizedBox(height: SignInStyles.signUpTopSpacing),
                          _buildSignUpPrompt(),
                          const SizedBox(height: SignInStyles.guestTopSpacing),
                          _buildGuestButton(),
                          const SizedBox(
                            height: SignInStyles.bottomIllustrationSpacing,
                          ),
                          const _BottomIllustration(),
                        ],
                      ),
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

  Widget _buildBackButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        tooltip: SignInStyles.backTooltip,
        onPressed: _isSigningIn
            ? null
            : () {
                Navigator.of(context).maybePop();
              },
        style: SignInStyles.backButtonStyle,
        icon: const Icon(
          SignInStyles.backIcon,
          size: SignInStyles.backIconSize,
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: SignInStyles.logoContainerSize,
        height: SignInStyles.logoContainerSize,
        padding: SignInStyles.logoPadding,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          gradient: SignInStyles.logoGradient,
          borderRadius: SignInStyles.logoRadius,
          boxShadow: SignInStyles.logoShadow,
        ),
        child: Image.asset(
          SignInStyles.logoAsset,
          fit: BoxFit.contain,
          semanticLabel: SignInStyles.logoSemanticLabel,
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Text.rich(
      const TextSpan(
        children: <InlineSpan>[
          TextSpan(text: SignInStyles.descriptionFirstPart),
          TextSpan(
            text: SignInStyles.appName,
            style: SignInStyles.descriptionHighlightStyle,
          ),
          TextSpan(text: SignInStyles.descriptionLastPart),
        ],
      ),
      textAlign: TextAlign.center,
      style: SignInStyles.descriptionStyle,
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          SignInStyles.emailLabel,
          style: SignInStyles.fieldLabelStyle,
        ),
        const SizedBox(height: SignInStyles.labelFieldSpacing),
        TextField(
          controller: emailController,
          enabled: !_isSigningIn,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const <String>[AutofillHints.email],
          style: SignInStyles.inputTextStyle,
          decoration: SignInStyles.emailDecoration,
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          SignInStyles.passwordLabel,
          style: SignInStyles.fieldLabelStyle,
        ),
        const SizedBox(height: SignInStyles.labelFieldSpacing),
        TextField(
          controller: passwordController,
          enabled: !_isSigningIn,
          obscureText: !isPasswordVisible,
          textInputAction: TextInputAction.done,
          autofillHints: const <String>[AutofillHints.password],
          style: SignInStyles.inputTextStyle,
          onSubmitted: (_) {
            _signIn();
          },
          decoration: SignInStyles.passwordDecoration.copyWith(
            suffixIcon: IconButton(
              tooltip: isPasswordVisible
                  ? SignInStyles.hidePasswordTooltip
                  : SignInStyles.showPasswordTooltip,
              onPressed: _isSigningIn ? null : _togglePasswordVisibility,
              icon: Icon(
                isPasswordVisible
                    ? SignInStyles.visiblePasswordIcon
                    : SignInStyles.hiddenPasswordIcon,
                color: SignInStyles.fieldSuffixIconColor,
                size: SignInStyles.fieldIconSize,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _isSigningIn
            ? null
            : () {
                // Forgot-password functionality will be added later.
              },
        style: SignInStyles.forgotPasswordButtonStyle,
        child: const Text(SignInStyles.forgotPasswordLabel),
      ),
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      height: SignInStyles.buttonHeight,
      child: ElevatedButton(
        onPressed: _isBusy ? null : _signIn,
        style: SignInStyles.signInButtonStyle,
        child: _isSigningIn
            ? const SizedBox.square(
                dimension: SignInStyles.loadingIndicatorSize,
                child: CircularProgressIndicator(
                  strokeWidth: SignInStyles.loadingStrokeWidth,
                  color: SignInStyles.surfaceColor,
                ),
              )
            : const Row(
                children: <Widget>[
                  Icon(
                    SignInStyles.signInIcon,
                    size: SignInStyles.buttonIconSize,
                  ),
                  Expanded(
                    child: Text(
                      SignInStyles.signInLabel,
                      textAlign: TextAlign.center,
                      style: SignInStyles.primaryButtonTextStyle,
                    ),
                  ),
                  Icon(
                    SignInStyles.forwardIcon,
                    size: SignInStyles.forwardIconSize,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      height: SignInStyles.buttonHeight,
      child: OutlinedButton(
        onPressed: _isBusy ? null : _signInWithGoogle,
        style: SignInStyles.googleButtonStyle,
        child: _isGoogleSigningIn
            ? const SizedBox.square(
                dimension: SignInStyles.loadingIndicatorSize,
                child: CircularProgressIndicator(
                  strokeWidth: SignInStyles.loadingStrokeWidth,
                  color: SignInStyles.primaryColor,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    SignInStyles.googleIconLetter,
                    style: SignInStyles.googleIconStyle,
                  ),
                  SizedBox(width: SignInStyles.googleIconSpacing),
                  Text(
                    SignInStyles.googleLabel,
                    style: SignInStyles.googleButtonTextStyle,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSignUpPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Text(
          SignInStyles.noAccountLabel,
          style: SignInStyles.accountPromptStyle,
        ),
        TextButton(
          onPressed: _isSigningIn ? null : _openSignUp,
          style: SignInStyles.signUpLinkButtonStyle,
          child: const Text(SignInStyles.signUpLabel),
        ),
      ],
    );
  }

  Widget _buildGuestButton() {
    return SizedBox(
      height: SignInStyles.buttonHeight,
      child: OutlinedButton(
        onPressed: _isBusy ? null : _continueAsGuest,
        style: SignInStyles.guestButtonStyle,
        child: _isRestoringGuest
            ? const SizedBox.square(
                dimension: SignInStyles.loadingIndicatorSize,
                child: CircularProgressIndicator(
                  strokeWidth: SignInStyles.loadingStrokeWidth,
                  color: SignInStyles.primaryColor,
                ),
              )
            : const Row(
                children: <Widget>[
                  Icon(
                    SignInStyles.guestIcon,
                    size: SignInStyles.buttonIconSize,
                  ),
                  Expanded(
                    child: Text(
                      SignInStyles.guestLabel,
                      textAlign: TextAlign.center,
                      style: SignInStyles.guestButtonTextStyle,
                    ),
                  ),
                  Icon(
                    SignInStyles.forwardIcon,
                    size: SignInStyles.forwardIconSize,
                    color: SignInStyles.forwardIconColor,
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
          gradient: SignInStyles.backgroundDecorationGradient,
        ),
      ),
    );
  }
}

class _BrailleDots extends StatelessWidget {
  const _BrailleDots();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Wrap(
        direction: Axis.vertical,
        spacing: SignInStyles.decorationDotSpacing,
        runSpacing: SignInStyles.decorationDotSpacing,
        children: List<Widget>.generate(SignInStyles.decorationDotCount, (
          int index,
        ) {
          return const DecoratedBox(
            decoration: BoxDecoration(
              color: SignInStyles.decorationDotColor,
              shape: BoxShape.circle,
              boxShadow: SignInStyles.decorationDotShadow,
            ),
            child: SizedBox.square(dimension: SignInStyles.decorationDotSize),
          );
        }, growable: false),
      ),
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
            color: SignInStyles.dividerColor,
            thickness: SignInStyles.dividerThickness,
          ),
        ),
        Padding(
          padding: SignInStyles.orLabelPadding,
          child: Text(SignInStyles.orLabel, style: SignInStyles.orLabelStyle),
        ),
        Expanded(
          child: Divider(
            color: SignInStyles.dividerColor,
            thickness: SignInStyles.dividerThickness,
          ),
        ),
      ],
    );
  }
}

class _BottomIllustration extends StatelessWidget {
  const _BottomIllustration();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: SignInStyles.illustrationWidth,
        height: SignInStyles.illustrationHeight,
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 0,
              bottom: 0,
              child: Icon(
                SignInStyles.illustrationBookIcon,
                size: SignInStyles.illustrationBookSize,
                color: SignInStyles.illustrationColor,
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: SignInStyles.illustrationBackgroundColor,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(
                      color: SignInStyles.illustrationColor,
                      width: SignInStyles.illustrationBorderWidth,
                    ),
                  ),
                ),
                child: SizedBox.square(
                  dimension: SignInStyles.illustrationBadgeSize,
                  child: Center(
                    child: Text(
                      SignInStyles.aiLabel,
                      style: SignInStyles.illustrationAiStyle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignInException implements Exception {
  const SignInException(this.message);

  final String message;

  @override
  String toString() => message;
}
