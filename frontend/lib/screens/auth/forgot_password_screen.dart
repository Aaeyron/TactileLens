import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth/auth_service.dart';
import '../../styles/screens/auth/forgot_password_screen_styles.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() {
    return _ForgotPasswordScreenState();
  }
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _emailFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _resetFormKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _resetCodeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _resetCodeFocus = FocusNode();
  final FocusNode _newPasswordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  Timer? _resendTimer;

  bool _codeRequested = false;
  bool _isSubmitting = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  int _resendSecondsRemaining = 0;

  bool get _canResend {
    return !_isSubmitting && _resendSecondsRemaining == 0;
  }

  @override
  void initState() {
    super.initState();

    _emailController.text = widget.initialEmail.trim();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();

    _emailController.dispose();
    _resetCodeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    _emailFocus.dispose();
    _resetCodeFocus.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();

    super.dispose();
  }

  String? _validateEmail(String? value) {
    final String email = value?.trim() ?? '';

    if (email.isEmpty) {
      return ForgotPasswordScreenStyles.emailRequiredMessage;
    }

    final RegExp emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailPattern.hasMatch(email)) {
      return ForgotPasswordScreenStyles.invalidEmailMessage;
    }

    return null;
  }

  String? _validateResetCode(String? value) {
    final String resetCode = value?.trim() ?? '';

    if (resetCode.isEmpty) {
      return ForgotPasswordScreenStyles.resetCodeRequiredMessage;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(resetCode)) {
      return ForgotPasswordScreenStyles.invalidResetCodeMessage;
    }

    return null;
  }

  String? _validateNewPassword(String? value) {
    final String password = value ?? '';

    if (password.isEmpty) {
      return ForgotPasswordScreenStyles.newPasswordRequiredMessage;
    }

    if (password.length < 8) {
      return ForgotPasswordScreenStyles.passwordTooShortMessage;
    }

    if (password.length > 128) {
      return ForgotPasswordScreenStyles.passwordTooLongMessage;
    }

    return null;
  }

  String? _validatePasswordConfirmation(String? value) {
    if (value == null || value.isEmpty) {
      return ForgotPasswordScreenStyles.confirmationRequiredMessage;
    }

    if (value != _newPasswordController.text) {
      return ForgotPasswordScreenStyles.passwordsDoNotMatchMessage;
    }

    return null;
  }

  Future<void> _requestResetCode({bool isResend = false}) async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (!isResend) {
      final bool formIsValid = _emailFormKey.currentState?.validate() ?? false;

      if (!formIsValid) {
        return;
      }
    } else if (_validateEmail(_emailController.text) != null) {
      _changeEmail();
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await AuthService.requestPasswordReset(
        email: _emailController.text,
      );

      final Map<String, dynamic> responseBody = _decodeResponseBody(
        response.body,
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (isResend) {
          _resetCodeController.clear();
        }

        setState(() {
          _codeRequested = true;
        });

        _startResendCooldown();

        _showMessage(
          isResend
              ? ForgotPasswordScreenStyles.codeResentMessage
              : ForgotPasswordScreenStyles.codeSentMessage,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _resetCodeFocus.requestFocus();
          }
        });

        return;
      }

      _showMessage(
        _readServerMessage(responseBody) ??
            ForgotPasswordScreenStyles.defaultRequestErrorMessage,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(ForgotPasswordScreenStyles.connectionErrorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();

    final bool formIsValid = _resetFormKey.currentState?.validate() ?? false;

    if (!formIsValid) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await AuthService.resetPassword(
        email: _emailController.text,
        resetCode: _resetCodeController.text,
        newPassword: _newPasswordController.text,
      );

      final Map<String, dynamic> responseBody = _decodeResponseBody(
        response.body,
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _resendTimer?.cancel();

        _resetCodeController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        await _showSuccessDialog();

        if (mounted) {
          Navigator.of(context).pop();
        }

        return;
      }

      _showMessage(
        _readServerMessage(responseBody) ??
            ForgotPasswordScreenStyles.defaultResetErrorMessage,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(ForgotPasswordScreenStyles.connectionErrorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();

    setState(() {
      _resendSecondsRemaining =
          ForgotPasswordScreenStyles.resendCooldown.inSeconds;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendSecondsRemaining <= 1) {
        timer.cancel();

        setState(() {
          _resendSecondsRemaining = 0;
        });

        return;
      }

      setState(() {
        _resendSecondsRemaining--;
      });
    });
  }

  void _changeEmail() {
    if (_isSubmitting) {
      return;
    }

    _resendTimer?.cancel();

    _resetCodeController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    setState(() {
      _codeRequested = false;
      _resendSecondsRemaining = 0;
      _showNewPassword = false;
      _showConfirmPassword = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _emailFocus.requestFocus();
      }
    });
  }

  Map<String, dynamic> _decodeResponseBody(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final dynamic decodedBody = jsonDecode(responseBody);

      if (decodedBody is Map<String, dynamic>) {
        return decodedBody;
      }

      if (decodedBody is Map) {
        return Map<String, dynamic>.from(decodedBody);
      }
    } catch (_) {
      return <String, dynamic>{};
    }

    return <String, dynamic>{};
  }

  String? _readServerMessage(Map<String, dynamic> responseBody) {
    final dynamic rawMessage = responseBody['message'];

    if (rawMessage is String && rawMessage.trim().isNotEmpty) {
      return rawMessage.trim();
    }

    return null;
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: ForgotPasswordScreenStyles.snackBarDuration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: ForgotPasswordScreenStyles.primaryColor,
          margin: ForgotPasswordScreenStyles.snackBarMargin,
          shape: const RoundedRectangleBorder(
            borderRadius: ForgotPasswordScreenStyles.snackBarRadius,
          ),
          content: Text(
            message,
            style: ForgotPasswordScreenStyles.snackBarTextStyle,
          ),
        ),
      );
  }

  Future<void> _showSuccessDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: ForgotPasswordScreenStyles.surfaceColor,
          shape: const RoundedRectangleBorder(
            borderRadius: ForgotPasswordScreenStyles.dialogRadius,
            side: BorderSide(color: ForgotPasswordScreenStyles.outlineColor),
          ),
          icon: const Icon(
            ForgotPasswordScreenStyles.successIcon,
            color: ForgotPasswordScreenStyles.successColor,
            size: 48,
          ),
          title: const Text(
            ForgotPasswordScreenStyles.successDialogTitle,
            textAlign: TextAlign.center,
            style: ForgotPasswordScreenStyles.dialogTitleStyle,
          ),
          content: const Text(
            ForgotPasswordScreenStyles.successDialogDescription,
            textAlign: TextAlign.center,
            style: ForgotPasswordScreenStyles.dialogDescriptionStyle,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            FilledButton(
              style: ForgotPasswordScreenStyles.dialogButtonStyle,
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(ForgotPasswordScreenStyles.returnToSignInLabel),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ForgotPasswordScreenStyles.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(),
              padding: ForgotPasswordScreenStyles.pagePadding,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ForgotPasswordScreenStyles.maximumContentWidth,
                    minHeight:
                        constraints.maxHeight -
                        ForgotPasswordScreenStyles.pagePadding.vertical,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _buildBackButton(),
                      const SizedBox(
                        height: ForgotPasswordScreenStyles.headerIconTopSpacing,
                      ),
                      _buildRecoveryIcon(),
                      const SizedBox(
                        height: ForgotPasswordScreenStyles.titleTopSpacing,
                      ),
                      const Text(
                        ForgotPasswordScreenStyles.screenTitle,
                        textAlign: TextAlign.center,
                        style: ForgotPasswordScreenStyles.screenTitleStyle,
                      ),
                      const SizedBox(
                        height:
                            ForgotPasswordScreenStyles.descriptionTopSpacing,
                      ),
                      const Text(
                        ForgotPasswordScreenStyles.screenDescription,
                        textAlign: TextAlign.center,
                        style:
                            ForgotPasswordScreenStyles.screenDescriptionStyle,
                      ),
                      const SizedBox(
                        height: ForgotPasswordScreenStyles.cardTopSpacing,
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _codeRequested
                            ? _buildResetPasswordCard()
                            : _buildRequestCodeCard(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        tooltip: ForgotPasswordScreenStyles.backTooltip,
        style: ForgotPasswordScreenStyles.backButtonStyle,
        onPressed: _isSubmitting
            ? null
            : () {
                if (_codeRequested) {
                  _changeEmail();
                  return;
                }

                Navigator.of(context).maybePop();
              },
        icon: const Icon(ForgotPasswordScreenStyles.backIcon),
      ),
    );
  }

  Widget _buildRecoveryIcon() {
    return Center(
      child: Container(
        width: ForgotPasswordScreenStyles.headerIconSize,
        height: ForgotPasswordScreenStyles.headerIconSize,
        decoration: const BoxDecoration(
          color: ForgotPasswordScreenStyles.iconBackgroundColor,
          borderRadius: ForgotPasswordScreenStyles.iconRadius,
        ),
        child: const Icon(
          ForgotPasswordScreenStyles.recoveryIcon,
          color: ForgotPasswordScreenStyles.brightPrimaryColor,
          size: ForgotPasswordScreenStyles.recoveryIconSize,
        ),
      ),
    );
  }

  Widget _buildRequestCodeCard() {
    return Container(
      key: const ValueKey<String>('request-code'),
      padding: ForgotPasswordScreenStyles.cardPadding,
      decoration: const BoxDecoration(
        color: ForgotPasswordScreenStyles.surfaceColor,
        borderRadius: ForgotPasswordScreenStyles.cardRadius,
        border: Border.fromBorderSide(ForgotPasswordScreenStyles.cardBorder),
        boxShadow: ForgotPasswordScreenStyles.cardShadow,
      ),
      child: Form(
        key: _emailFormKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              ForgotPasswordScreenStyles.requestTitle,
              style: ForgotPasswordScreenStyles.formTitleStyle,
            ),
            const SizedBox(
              height: ForgotPasswordScreenStyles.formDescriptionSpacing,
            ),
            const Text(
              ForgotPasswordScreenStyles.requestDescription,
              style: ForgotPasswordScreenStyles.formDescriptionStyle,
            ),
            const SizedBox(
              height: ForgotPasswordScreenStyles.formFieldsSpacing,
            ),
            const Text(
              ForgotPasswordScreenStyles.emailLabel,
              style: ForgotPasswordScreenStyles.fieldLabelStyle,
            ),
            const SizedBox(
              height: ForgotPasswordScreenStyles.labelFieldSpacing,
            ),
            TextFormField(
              controller: _emailController,
              focusNode: _emailFocus,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const <String>[AutofillHints.email],
              autocorrect: false,
              validator: _validateEmail,
              style: ForgotPasswordScreenStyles.fieldTextStyle,
              decoration: ForgotPasswordScreenStyles.fieldDecoration(
                hint: ForgotPasswordScreenStyles.emailHint,
                icon: ForgotPasswordScreenStyles.emailIcon,
              ),
              onFieldSubmitted: (_) {
                _requestResetCode();
              },
            ),
            const SizedBox(height: ForgotPasswordScreenStyles.buttonTopSpacing),
            SizedBox(
              width: double.infinity,
              height: ForgotPasswordScreenStyles.buttonHeight,
              child: FilledButton(
                style: ForgotPasswordScreenStyles.primaryButtonStyle,
                onPressed: _isSubmitting ? null : _requestResetCode,
                child: _isSubmitting
                    ? const SizedBox.square(
                        dimension:
                            ForgotPasswordScreenStyles.buttonProgressSize,
                        child: CircularProgressIndicator(
                          strokeWidth: ForgotPasswordScreenStyles
                              .buttonProgressStrokeWidth,
                          color: ForgotPasswordScreenStyles.surfaceColor,
                        ),
                      )
                    : const Text(
                        ForgotPasswordScreenStyles.sendCodeLabel,
                        style: ForgotPasswordScreenStyles.buttonTextStyle,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetPasswordCard() {
    return Container(
      key: const ValueKey<String>('reset-password'),
      padding: ForgotPasswordScreenStyles.cardPadding,
      decoration: const BoxDecoration(
        color: ForgotPasswordScreenStyles.surfaceColor,
        borderRadius: ForgotPasswordScreenStyles.cardRadius,
        border: Border.fromBorderSide(ForgotPasswordScreenStyles.cardBorder),
        boxShadow: ForgotPasswordScreenStyles.cardShadow,
      ),
      child: Form(
        key: _resetFormKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              ForgotPasswordScreenStyles.resetTitle,
              style: ForgotPasswordScreenStyles.formTitleStyle,
            ),
            const SizedBox(
              height: ForgotPasswordScreenStyles.formDescriptionSpacing,
            ),
            const Text(
              ForgotPasswordScreenStyles.resetDescription,
              style: ForgotPasswordScreenStyles.formDescriptionStyle,
            ),
            const SizedBox(
              height: ForgotPasswordScreenStyles.secondaryActionSpacing,
            ),
            Text(
              _emailController.text.trim(),
              style: ForgotPasswordScreenStyles.informationTextStyle,
            ),
            TextButton(
              style: ForgotPasswordScreenStyles.secondaryButtonStyle,
              onPressed: _isSubmitting ? null : _changeEmail,
              child: const Text(ForgotPasswordScreenStyles.changeEmailLabel),
            ),
            const SizedBox(height: ForgotPasswordScreenStyles.fieldSpacing),
            const Text(
              ForgotPasswordScreenStyles.resetCodeLabel,
              style: ForgotPasswordScreenStyles.fieldLabelStyle,
            ),
            const SizedBox(
              height: ForgotPasswordScreenStyles.labelFieldSpacing,
            ),
            TextFormField(
              controller: _resetCodeController,
              focusNode: _resetCodeFocus,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.oneTimeCode],
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              validator: _validateResetCode,
              style: ForgotPasswordScreenStyles.fieldTextStyle,
              decoration: ForgotPasswordScreenStyles.fieldDecoration(
                hint: ForgotPasswordScreenStyles.resetCodeHint,
                icon: ForgotPasswordScreenStyles.resetCodeIcon,
              ).copyWith(counterText: ''),
              onFieldSubmitted: (_) {
                _newPasswordFocus.requestFocus();
              },
            ),
            const SizedBox(height: ForgotPasswordScreenStyles.fieldSpacing),
            _buildNewPasswordField(),
            const SizedBox(height: ForgotPasswordScreenStyles.fieldSpacing),
            _buildConfirmPasswordField(),
            const SizedBox(height: ForgotPasswordScreenStyles.fieldSpacing),
            _buildPasswordRequirements(),
            const SizedBox(height: ForgotPasswordScreenStyles.buttonTopSpacing),
            SizedBox(
              width: double.infinity,
              height: ForgotPasswordScreenStyles.buttonHeight,
              child: FilledButton(
                style: ForgotPasswordScreenStyles.primaryButtonStyle,
                onPressed: _isSubmitting ? null : _resetPassword,
                child: _isSubmitting
                    ? const SizedBox.square(
                        dimension:
                            ForgotPasswordScreenStyles.buttonProgressSize,
                        child: CircularProgressIndicator(
                          strokeWidth: ForgotPasswordScreenStyles
                              .buttonProgressStrokeWidth,
                          color: ForgotPasswordScreenStyles.surfaceColor,
                        ),
                      )
                    : const Text(
                        ForgotPasswordScreenStyles.resetPasswordLabel,
                        style: ForgotPasswordScreenStyles.buttonTextStyle,
                      ),
              ),
            ),
            const SizedBox(
              height: ForgotPasswordScreenStyles.secondaryActionSpacing,
            ),
            Center(
              child: TextButton(
                style: ForgotPasswordScreenStyles.secondaryButtonStyle,
                onPressed: _canResend
                    ? () {
                        _requestResetCode(isResend: true);
                      }
                    : null,
                child: Text(
                  _resendSecondsRemaining > 0
                      ? ForgotPasswordScreenStyles.resendCountdownLabel(
                          _resendSecondsRemaining,
                        )
                      : ForgotPasswordScreenStyles.resendCodeLabel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          ForgotPasswordScreenStyles.newPasswordLabel,
          style: ForgotPasswordScreenStyles.fieldLabelStyle,
        ),
        const SizedBox(height: ForgotPasswordScreenStyles.labelFieldSpacing),
        TextFormField(
          controller: _newPasswordController,
          focusNode: _newPasswordFocus,
          enabled: !_isSubmitting,
          obscureText: !_showNewPassword,
          textInputAction: TextInputAction.next,
          autofillHints: const <String>[AutofillHints.newPassword],
          inputFormatters: <TextInputFormatter>[
            LengthLimitingTextInputFormatter(128),
          ],
          validator: _validateNewPassword,
          style: ForgotPasswordScreenStyles.fieldTextStyle,
          decoration: ForgotPasswordScreenStyles.fieldDecoration(
            hint: ForgotPasswordScreenStyles.newPasswordHint,
            icon: ForgotPasswordScreenStyles.newPasswordIcon,
            suffixIcon: IconButton(
              tooltip: _showNewPassword
                  ? ForgotPasswordScreenStyles.hidePasswordTooltip
                  : ForgotPasswordScreenStyles.showPasswordTooltip,
              onPressed: _isSubmitting
                  ? null
                  : () {
                      setState(() {
                        _showNewPassword = !_showNewPassword;
                      });
                    },
              icon: Icon(
                _showNewPassword
                    ? ForgotPasswordScreenStyles.passwordVisibleIcon
                    : ForgotPasswordScreenStyles.passwordHiddenIcon,
              ),
            ),
          ),
          onFieldSubmitted: (_) {
            _confirmPasswordFocus.requestFocus();
          },
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          ForgotPasswordScreenStyles.confirmPasswordLabel,
          style: ForgotPasswordScreenStyles.fieldLabelStyle,
        ),
        const SizedBox(height: ForgotPasswordScreenStyles.labelFieldSpacing),
        TextFormField(
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocus,
          enabled: !_isSubmitting,
          obscureText: !_showConfirmPassword,
          textInputAction: TextInputAction.done,
          autofillHints: const <String>[AutofillHints.newPassword],
          inputFormatters: <TextInputFormatter>[
            LengthLimitingTextInputFormatter(128),
          ],
          validator: _validatePasswordConfirmation,
          style: ForgotPasswordScreenStyles.fieldTextStyle,
          decoration: ForgotPasswordScreenStyles.fieldDecoration(
            hint: ForgotPasswordScreenStyles.confirmPasswordHint,
            icon: ForgotPasswordScreenStyles.confirmPasswordIcon,
            suffixIcon: IconButton(
              tooltip: _showConfirmPassword
                  ? ForgotPasswordScreenStyles.hidePasswordTooltip
                  : ForgotPasswordScreenStyles.showPasswordTooltip,
              onPressed: _isSubmitting
                  ? null
                  : () {
                      setState(() {
                        _showConfirmPassword = !_showConfirmPassword;
                      });
                    },
              icon: Icon(
                _showConfirmPassword
                    ? ForgotPasswordScreenStyles.passwordVisibleIcon
                    : ForgotPasswordScreenStyles.passwordHiddenIcon,
              ),
            ),
          ),
          onFieldSubmitted: (_) {
            _resetPassword();
          },
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: ForgotPasswordScreenStyles.informationBackgroundColor,
        borderRadius: ForgotPasswordScreenStyles.fieldRadius,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            ForgotPasswordScreenStyles.passwordRequirementsTitle,
            style: ForgotPasswordScreenStyles.requirementsTitleStyle,
          ),
          SizedBox(height: 8),
          _PasswordRequirement(
            text: ForgotPasswordScreenStyles.passwordLengthRequirement,
          ),
          SizedBox(height: 6),
          _PasswordRequirement(
            text: ForgotPasswordScreenStyles.passwordMatchRequirement,
          ),
        ],
      ),
    );
  }
}

class _PasswordRequirement extends StatelessWidget {
  const _PasswordRequirement({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(
          ForgotPasswordScreenStyles.requirementIcon,
          size: 17,
          color: ForgotPasswordScreenStyles.brightPrimaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: ForgotPasswordScreenStyles.requirementTextStyle,
          ),
        ),
      ],
    );
  }
}
