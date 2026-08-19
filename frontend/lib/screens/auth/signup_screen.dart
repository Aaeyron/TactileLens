import 'package:flutter/material.dart';

import '../../services/auth/auth_service.dart';
import '../../styles/screens/auth/signup_screen_styles.dart';
import 'signin_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() {
    return _SignUpScreenState();
  }
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController firstNameController =
      TextEditingController();

  final TextEditingController lastNameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool _isRegistering = false;

  String selectedRole = SignUpStyles.studentRole;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> _register() async {
    if (_isRegistering) {
      return;
    }

    final String firstName =
        firstNameController.text.trim();

    final String lastName =
        lastNameController.text.trim();

    final String email = emailController.text.trim();

    final String password = passwordController.text;

    final String confirmPassword =
        confirmPasswordController.text;

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage(SignUpStyles.emptyFieldsMessage);
      return;
    }

    final RegExp emailPattern = RegExp(
      r'^[\w\.-]+@([\w-]+\.)+[a-zA-Z]{2,}$',
    );

    if (!emailPattern.hasMatch(email)) {
      _showMessage(SignUpStyles.invalidEmailMessage);
      return;
    }

    if (password != confirmPassword) {
      _showMessage(
        SignUpStyles.passwordMismatchMessage,
      );
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      final response = await AuthService.registerUser(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        role: selectedRole,
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 201) {
        _showMessage(
          SignUpStyles.accountCreatedMessage,
        );

        await Navigator.of(context)
            .pushReplacement<void, void>(
          MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return const SignInScreen();
            },
          ),
        );

        return;
      }

      if (response.statusCode == 409) {
        _showMessage(
          SignUpStyles.emailExistsMessage,
        );

        return;
      }

      _showMessage(
        SignUpStyles.registrationFailedMessage,
      );
    } catch (error, stackTrace) {
      debugPrint('Registration failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      _showMessage(
        SignUpStyles.connectionErrorMessage,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: SignUpStyles.snackBarDuration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: SignUpStyles.primaryColor,
          margin: SignUpStyles.snackBarMargin,
          shape: const RoundedRectangleBorder(
            borderRadius: SignUpStyles.snackBarRadius,
          ),
          content: Text(
            message,
            style: SignUpStyles.snackBarTextStyle,
          ),
        ),
      );
  }

  void _selectRole(String role) {
    if (_isRegistering) {
      return;
    }

    setState(() {
      selectedRole = role;
    });
  }

  void _togglePasswordVisibility() {
    if (_isRegistering) {
      return;
    }

    setState(() {
      isPasswordVisible = !isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    if (_isRegistering) {
      return;
    }

    setState(() {
      isConfirmPasswordVisible =
          !isConfirmPasswordVisible;
    });
  }

  void _openSignIn() {
    if (_isRegistering) {
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const SignInScreen();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SignUpStyles.backgroundColor,
      body: Stack(
        children: <Widget>[
          const Positioned(
            top: SignUpStyles.topDecorationOffset,
            right: SignUpStyles.topDecorationOffset,
            child: _BackgroundCircle(
              size: SignUpStyles.topDecorationSize,
            ),
          ),
          const Positioned(
            bottom:
                SignUpStyles.bottomDecorationOffset,
            left: SignUpStyles.bottomDecorationOffset,
            child: _BackgroundCircle(
              size: SignUpStyles.bottomDecorationSize,
            ),
          ),
          const Positioned(
            top: SignUpStyles.leftDotsTop,
            left: SignUpStyles.dotsSideOffset,
            child: _BrailleDots(),
          ),
          const Positioned(
            top: SignUpStyles.rightDotsTop,
            right: SignUpStyles.dotsSideOffset,
            child: _BrailleDots(),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: SignUpStyles.pagePadding,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildBackButton(),
                    const SizedBox(
                      height: SignUpStyles.logoTopSpacing,
                    ),
                    _buildLogo(),
                    const SizedBox(
                      height:
                          SignUpStyles.logoBottomSpacing,
                    ),
                    _buildTitle(),
                    const SizedBox(
                      height:
                          SignUpStyles.descriptionSpacing,
                    ),
                    _buildDescription(),
                    const SizedBox(
                      height: SignUpStyles.formTopSpacing,
                    ),
                    _buildFirstNameField(),
                    const SizedBox(
                      height: SignUpStyles.fieldSpacing,
                    ),
                    _buildLastNameField(),
                    const SizedBox(
                      height: SignUpStyles.fieldSpacing,
                    ),
                    _buildEmailField(),
                    const SizedBox(
                      height: SignUpStyles.fieldSpacing,
                    ),
                    _buildPasswordField(),
                    const SizedBox(
                      height:
                          SignUpStyles.passwordHelpSpacing,
                    ),
                    const Text(
                      SignUpStyles.passwordRequirement,
                      style:
                          SignUpStyles.passwordHelpStyle,
                    ),
                    const SizedBox(
                      height: SignUpStyles.fieldSpacing,
                    ),
                    _buildConfirmPasswordField(),
                    const SizedBox(
                      height:
                          SignUpStyles.roleTopSpacing,
                    ),
                    const Text(
                      SignUpStyles.roleLabel,
                      style: SignUpStyles.fieldLabelStyle,
                    ),
                    const SizedBox(
                      height:
                          SignUpStyles.roleCardsSpacing,
                    ),
                    _buildRoleSelection(),
                    const SizedBox(
                      height:
                          SignUpStyles.signUpTopSpacing,
                    ),
                    _buildSignUpButton(),
                    const SizedBox(
                      height:
                          SignUpStyles.dividerSpacing,
                    ),
                    const _OrDivider(),
                    const SizedBox(
                      height:
                          SignUpStyles.dividerSpacing,
                    ),
                    _buildGoogleButton(),
                    const SizedBox(
                      height:
                          SignUpStyles.signInPromptSpacing,
                    ),
                    _buildSignInPrompt(),
                    const SizedBox(
                      height:
                          SignUpStyles.illustrationSpacing,
                    ),
                    const _BottomIllustration(),
                    const SizedBox(
                      height: SignUpStyles.bottomSpacing,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        tooltip: SignUpStyles.backTooltip,
        onPressed: _isRegistering
            ? null
            : () {
                Navigator.of(context).maybePop();
              },
        style: SignUpStyles.backButtonStyle,
        icon: const Icon(
          SignUpStyles.backIcon,
          size: SignUpStyles.backIconSize,
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: SignUpStyles.logoContainerSize,
        height: SignUpStyles.logoContainerSize,
        padding: SignUpStyles.logoPadding,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          gradient: SignUpStyles.logoGradient,
          borderRadius: SignUpStyles.logoRadius,
          boxShadow: SignUpStyles.logoShadow,
        ),
        child: Image.asset(
          SignUpStyles.logoAsset,
          fit: BoxFit.contain,
          semanticLabel: SignUpStyles.logoSemanticLabel,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text.rich(
      const TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: SignUpStyles.titleFirstPart,
            style: SignUpStyles.titleDarkStyle,
          ),
          TextSpan(
            text: SignUpStyles.titleHighlightedPart,
            style: SignUpStyles.titleBlueStyle,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription() {
    return Text.rich(
      const TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: SignUpStyles.descriptionFirstPart,
          ),
          TextSpan(
            text: SignUpStyles.appName,
            style:
                SignUpStyles.descriptionHighlightStyle,
          ),
          TextSpan(
            text: SignUpStyles.descriptionLastPart,
          ),
        ],
      ),
      textAlign: TextAlign.center,
      style: SignUpStyles.descriptionStyle,
    );
  }

  Widget _buildFirstNameField() {
    return _LabeledField(
      label: SignUpStyles.firstNameLabel,
      child: TextField(
        controller: firstNameController,
        enabled: !_isRegistering,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        autofillHints: const <String>[
          AutofillHints.givenName,
        ],
        style: SignUpStyles.inputTextStyle,
        decoration:
            SignUpStyles.firstNameDecoration,
      ),
    );
  }

  Widget _buildLastNameField() {
    return _LabeledField(
      label: SignUpStyles.lastNameLabel,
      child: TextField(
        controller: lastNameController,
        enabled: !_isRegistering,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        autofillHints: const <String>[
          AutofillHints.familyName,
        ],
        style: SignUpStyles.inputTextStyle,
        decoration: SignUpStyles.lastNameDecoration,
      ),
    );
  }

  Widget _buildEmailField() {
    return _LabeledField(
      label: SignUpStyles.emailLabel,
      child: TextField(
        controller: emailController,
        enabled: !_isRegistering,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autofillHints: const <String>[
          AutofillHints.email,
        ],
        style: SignUpStyles.inputTextStyle,
        decoration: SignUpStyles.emailDecoration,
      ),
    );
  }

  Widget _buildPasswordField() {
    return _LabeledField(
      label: SignUpStyles.passwordLabel,
      child: TextField(
        controller: passwordController,
        enabled: !_isRegistering,
        obscureText: !isPasswordVisible,
        textInputAction: TextInputAction.next,
        autofillHints: const <String>[
          AutofillHints.newPassword,
        ],
        style: SignUpStyles.inputTextStyle,
        decoration:
            SignUpStyles.passwordDecoration.copyWith(
          suffixIcon: IconButton(
            tooltip: isPasswordVisible
                ? SignUpStyles.hidePasswordTooltip
                : SignUpStyles.showPasswordTooltip,
            onPressed: _isRegistering
                ? null
                : _togglePasswordVisibility,
            icon: Icon(
              isPasswordVisible
                  ? SignUpStyles.visiblePasswordIcon
                  : SignUpStyles.hiddenPasswordIcon,
              color:
                  SignUpStyles.fieldSuffixIconColor,
              size: SignUpStyles.fieldIconSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return _LabeledField(
      label: SignUpStyles.confirmPasswordLabel,
      child: TextField(
        controller: confirmPasswordController,
        enabled: !_isRegistering,
        obscureText: !isConfirmPasswordVisible,
        textInputAction: TextInputAction.done,
        autofillHints: const <String>[
          AutofillHints.newPassword,
        ],
        onSubmitted: (_) {
          _register();
        },
        style: SignUpStyles.inputTextStyle,
        decoration: SignUpStyles
            .confirmPasswordDecoration
            .copyWith(
          suffixIcon: IconButton(
            tooltip: isConfirmPasswordVisible
                ? SignUpStyles.hidePasswordTooltip
                : SignUpStyles.showPasswordTooltip,
            onPressed: _isRegistering
                ? null
                : _toggleConfirmPasswordVisibility,
            icon: Icon(
              isConfirmPasswordVisible
                  ? SignUpStyles.visiblePasswordIcon
                  : SignUpStyles.hiddenPasswordIcon,
              color:
                  SignUpStyles.fieldSuffixIconColor,
              size: SignUpStyles.fieldIconSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Row(
      children: <Widget>[
        Expanded(
          child: _RoleCard(
            role: SignUpStyles.studentRole,
            title: SignUpStyles.studentTitle,
            description:
                SignUpStyles.studentDescription,
            icon: SignUpStyles.studentIcon,
            isSelected:
                selectedRole ==
                SignUpStyles.studentRole,
            onTap: () {
              _selectRole(SignUpStyles.studentRole);
            },
          ),
        ),
        const SizedBox(
          width: SignUpStyles.roleCardGap,
        ),
        Expanded(
          child: _RoleCard(
            role: SignUpStyles.educatorRole,
            title: SignUpStyles.educatorTitle,
            description:
                SignUpStyles.educatorDescription,
            icon: SignUpStyles.educatorIcon,
            isSelected:
                selectedRole ==
                SignUpStyles.educatorRole,
            onTap: () {
              _selectRole(SignUpStyles.educatorRole);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      height: SignUpStyles.buttonHeight,
      child: ElevatedButton(
        onPressed:
            _isRegistering ? null : _register,
        style: SignUpStyles.signUpButtonStyle,
        child: _isRegistering
            ? const SizedBox.square(
                dimension:
                    SignUpStyles.loadingIndicatorSize,
                child: CircularProgressIndicator(
                  strokeWidth:
                      SignUpStyles.loadingStrokeWidth,
                  color: SignUpStyles.surfaceColor,
                ),
              )
            : const Row(
                children: <Widget>[
                  Icon(
                    SignUpStyles.signUpIcon,
                    size: SignUpStyles.buttonIconSize,
                  ),
                  Expanded(
                    child: Text(
                      SignUpStyles.signUpLabel,
                      textAlign: TextAlign.center,
                      style:
                          SignUpStyles.primaryButtonTextStyle,
                    ),
                  ),
                  Icon(
                    SignUpStyles.forwardIcon,
                    size: SignUpStyles.forwardIconSize,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      height: SignUpStyles.buttonHeight,
      child: OutlinedButton(
        // Google registration is intentionally disabled for now.
        onPressed: null,
        style: SignUpStyles.googleButtonStyle,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              SignUpStyles.googleIconLetter,
              style: SignUpStyles.googleIconStyle,
            ),
            SizedBox(
              width: SignUpStyles.googleIconSpacing,
            ),
            Text(
              SignUpStyles.googleLabel,
              style: SignUpStyles.googleButtonTextStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Text(
          SignUpStyles.hasAccountLabel,
          style: SignUpStyles.accountPromptStyle,
        ),
        TextButton(
          onPressed:
              _isRegistering ? null : _openSignIn,
          style: SignUpStyles.signInLinkButtonStyle,
          child: const Text(
            SignUpStyles.signInLabel,
          ),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: SignUpStyles.fieldLabelStyle,
        ),
        const SizedBox(
          height: SignUpStyles.labelFieldSpacing,
        ),
        child,
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String role;
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: role,
      selected: isSelected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: SignUpStyles.roleCardRadius,
          child: AnimatedContainer(
            duration:
                SignUpStyles.roleAnimationDuration,
            curve: Curves.easeOut,
            height: SignUpStyles.roleCardHeight,
            padding: SignUpStyles.roleCardPadding,
            decoration: BoxDecoration(
              color: isSelected
                  ? SignUpStyles.selectedRoleBackground
                  : SignUpStyles.surfaceColor,
              borderRadius:
                  SignUpStyles.roleCardRadius,
              border: Border.all(
                color: isSelected
                    ? SignUpStyles.brightPrimaryColor
                    : SignUpStyles.outlineColor,
                width: isSelected
                    ? SignUpStyles
                        .selectedRoleBorderWidth
                    : SignUpStyles
                        .roleBorderWidth,
              ),
              boxShadow: SignUpStyles.roleCardShadow,
            ),
            child: Stack(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width:
                          SignUpStyles.roleIconContainerSize,
                      height:
                          SignUpStyles.roleIconContainerSize,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? SignUpStyles
                                .selectedRoleIconBackground
                            : SignUpStyles
                                .unselectedRoleIconBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: SignUpStyles.roleIconSize,
                        color: isSelected
                            ? SignUpStyles
                                .brightPrimaryColor
                            : SignUpStyles
                                .educatorColor,
                      ),
                    ),
                    const SizedBox(
                      width:
                          SignUpStyles.roleContentSpacing,
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: SignUpStyles
                                .roleTitleStyle,
                          ),
                          const SizedBox(
                            height: SignUpStyles
                                .roleDescriptionSpacing,
                          ),
                          Text(
                            description,
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: SignUpStyles
                                .roleDescriptionStyle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width:
                        SignUpStyles.roleSelectionSize,
                    height:
                        SignUpStyles.roleSelectionSize,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? SignUpStyles
                              .brightPrimaryColor
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? SignUpStyles
                                .brightPrimaryColor
                            : SignUpStyles
                                .unselectedRoleCircleColor,
                        width: SignUpStyles
                            .roleSelectionBorderWidth,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color:
                                SignUpStyles.surfaceColor,
                            size: SignUpStyles
                                .roleCheckIconSize,
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackgroundCircle extends StatelessWidget {
  const _BackgroundCircle({
    required this.size,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient:
              SignUpStyles.backgroundDecorationGradient,
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
      child: Column(
        children: List<Widget>.generate(
          SignUpStyles.decorationDotRows,
          (int rowIndex) {
            return Padding(
              padding: EdgeInsets.only(
                bottom:
                    rowIndex ==
                        SignUpStyles.decorationDotRows - 1
                    ? 0
                    : SignUpStyles.decorationDotSpacing,
              ),
              child: const Row(
                children: <Widget>[
                  _DecorationDot(),
                  SizedBox(
                    width:
                        SignUpStyles.decorationDotSpacing,
                  ),
                  _DecorationDot(),
                ],
              ),
            );
          },
          growable: false,
        ),
      ),
    );
  }
}

class _DecorationDot extends StatelessWidget {
  const _DecorationDot();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: SignUpStyles.decorationDotColor,
        shape: BoxShape.circle,
        boxShadow:
            SignUpStyles.decorationDotShadow,
      ),
      child: SizedBox.square(
        dimension: SignUpStyles.decorationDotSize,
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
            color: SignUpStyles.dividerColor,
            thickness: SignUpStyles.dividerThickness,
          ),
        ),
        Padding(
          padding: SignUpStyles.orLabelPadding,
          child: Text(
            SignUpStyles.orLabel,
            style: SignUpStyles.orLabelStyle,
          ),
        ),
        Expanded(
          child: Divider(
            color: SignUpStyles.dividerColor,
            thickness: SignUpStyles.dividerThickness,
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
      child: Icon(
        SignUpStyles.illustrationIcon,
        size: SignUpStyles.illustrationSize,
        color: SignUpStyles.illustrationColor,
      ),
    );
  }
}