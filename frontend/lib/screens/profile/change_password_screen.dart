import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth/auth_service.dart';
import '../../styles/screens/profile/change_password_screen_styles.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() {
    return _ChangePasswordScreenState();
  }
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _currentPasswordController =
      TextEditingController();

  final TextEditingController _newPasswordController = TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _currentPasswordFocus = FocusNode();
  final FocusNode _newPasswordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  late final AnimationController _entranceController;
  late final Animation<double> _entranceOpacity;
  late final Animation<Offset> _entrancePosition;

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    _initializeEntranceAnimation();
  }

  void _initializeEntranceAnimation() {
    _entranceController = AnimationController(
      vsync: this,
      duration: ChangePasswordScreenStyles.entranceDuration,
    );

    final CurvedAnimation entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: ChangePasswordScreenStyles.entranceCurve,
    );

    _entranceOpacity = entranceAnimation;

    _entrancePosition = Tween<Offset>(
      begin: ChangePasswordScreenStyles.entranceBeginOffset,
      end: Offset.zero,
    ).animate(entranceAnimation);

    Future<void>.delayed(ChangePasswordScreenStyles.entranceDelay, () {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();

    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    _currentPasswordFocus.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();

    super.dispose();
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return ChangePasswordScreenStyles.currentPasswordRequired;
    }

    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return ChangePasswordScreenStyles.newPasswordRequired;
    }

    if (value.length < 8) {
      return ChangePasswordScreenStyles.passwordTooShort;
    }

    if (value.length > 128) {
      return ChangePasswordScreenStyles.passwordTooLong;
    }

    if (value == _currentPasswordController.text) {
      return ChangePasswordScreenStyles.samePasswordError;
    }

    return null;
  }

  String? _validatePasswordConfirmation(String? value) {
    if (value == null || value.isEmpty) {
      return ChangePasswordScreenStyles.confirmationRequired;
    }

    if (value != _newPasswordController.text) {
      return ChangePasswordScreenStyles.passwordsDoNotMatch;
    }

    return null;
  }

  Future<void> _submitPasswordChange() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();

    final bool formIsValid = _formKey.currentState?.validate() ?? false;

    if (!formIsValid) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await AuthService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      final Map<String, dynamic> responseBody = _decodeResponseBody(
        response.body,
      );

      final String responseCode = responseBody['code']?.toString().trim() ?? '';

      final String responseMessage =
          responseBody['message']?.toString().trim() ?? '';

      if (!mounted) {
        return;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        await _showSuccessDialog();

        if (mounted) {
          Navigator.of(context).maybePop();
        }

        return;
      }

      if (responseCode == 'google_password_managed') {
        await _showGooglePasswordDialog();
        return;
      }

      _showMessage(
        responseMessage.isEmpty
            ? ChangePasswordScreenStyles.defaultErrorMessage
            : responseMessage,
      );
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }

      final String message = error.message.toString().trim();

      _showMessage(
        message.isEmpty
            ? ChangePasswordScreenStyles.sessionUnavailableMessage
            : message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(ChangePasswordScreenStyles.defaultErrorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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

  Future<void> _showSuccessDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: ChangePasswordScreenStyles.surfaceColor,
          shape: const RoundedRectangleBorder(
            borderRadius: ChangePasswordScreenStyles.dialogRadius,
            side: BorderSide(color: ChangePasswordScreenStyles.outlineColor),
          ),
          icon: const Icon(
            ChangePasswordScreenStyles.successIcon,
            color: ChangePasswordScreenStyles.successColor,
            size: 48,
          ),
          title: const Text(
            ChangePasswordScreenStyles.successTitle,
            textAlign: TextAlign.center,
            style: ChangePasswordScreenStyles.dialogTitleStyle,
          ),
          content: const Text(
            ChangePasswordScreenStyles.successDescription,
            textAlign: TextAlign.center,
            style: ChangePasswordScreenStyles.dialogDescriptionStyle,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ChangePasswordScreenStyles.primaryColor,
                foregroundColor: ChangePasswordScreenStyles.surfaceColor,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(ChangePasswordScreenStyles.doneLabel),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showGooglePasswordDialog() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: ChangePasswordScreenStyles.surfaceColor,
          shape: const RoundedRectangleBorder(
            borderRadius: ChangePasswordScreenStyles.dialogRadius,
            side: BorderSide(color: ChangePasswordScreenStyles.outlineColor),
          ),
          icon: const Icon(
            ChangePasswordScreenStyles.googleIcon,
            color: ChangePasswordScreenStyles.primaryColor,
            size: 48,
          ),
          title: const Text(
            ChangePasswordScreenStyles.googlePasswordTitle,
            textAlign: TextAlign.center,
            style: ChangePasswordScreenStyles.dialogTitleStyle,
          ),
          content: const Text(
            ChangePasswordScreenStyles.googlePasswordDescription,
            textAlign: TextAlign.center,
            style: ChangePasswordScreenStyles.dialogDescriptionStyle,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ChangePasswordScreenStyles.primaryColor,
                foregroundColor: ChangePasswordScreenStyles.surfaceColor,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(ChangePasswordScreenStyles.closeLabel),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: ChangePasswordScreenStyles.snackBarDuration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: ChangePasswordScreenStyles.primaryColor,
          margin: ChangePasswordScreenStyles.snackBarMargin,
          shape: const RoundedRectangleBorder(
            borderRadius: ChangePasswordScreenStyles.snackBarRadius,
          ),
          content: Text(
            message,
            style: ChangePasswordScreenStyles.snackBarTextStyle,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: ChangePasswordScreenStyles.backgroundColor,
        body: FadeTransition(
          opacity: _entranceOpacity,
          child: SlideTransition(
            position: _entrancePosition,
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverPadding(
                  padding: ChangePasswordScreenStyles.contentPadding,
                  sliver: SliverToBoxAdapter(child: _buildPasswordForm()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final double statusBarHeight = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        ChangePasswordScreenStyles.headerHorizontalPadding,
        statusBarHeight + ChangePasswordScreenStyles.headerTopPadding,
        ChangePasswordScreenStyles.headerHorizontalPadding,
        ChangePasswordScreenStyles.headerBottomPadding,
      ),
      decoration: const BoxDecoration(
        gradient: ChangePasswordScreenStyles.headerGradient,
        borderRadius: ChangePasswordScreenStyles.headerRadius,
      ),
      child: Stack(
        children: <Widget>[
          const Positioned(
            right: ChangePasswordScreenStyles.decorationRight,
            bottom: ChangePasswordScreenStyles.decorationBottom,
            child: _HeaderBrailleDecoration(),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    tooltip: ChangePasswordScreenStyles.backTooltip,
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            Navigator.of(context).maybePop();
                          },
                    style: ChangePasswordScreenStyles.backButtonStyle,
                    icon: const Icon(
                      ChangePasswordScreenStyles.backIcon,
                      size: ChangePasswordScreenStyles.backIconSize,
                    ),
                  ),
                  const SizedBox(
                    width: ChangePasswordScreenStyles.headerBackSpacing,
                  ),
                  const Expanded(
                    child: Text(
                      ChangePasswordScreenStyles.screenTitle,
                      style: ChangePasswordScreenStyles.headerTitleStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: ChangePasswordScreenStyles.headerTextSpacing,
              ),
              const Padding(
                padding: ChangePasswordScreenStyles.headerDescriptionPadding,
                child: SizedBox(
                  width: ChangePasswordScreenStyles.headerDescriptionWidth,
                  child: Text(
                    ChangePasswordScreenStyles.screenDescription,
                    style: ChangePasswordScreenStyles.headerDescriptionStyle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Container(
      padding: ChangePasswordScreenStyles.formCardPadding,
      decoration: const BoxDecoration(
        color: ChangePasswordScreenStyles.surfaceColor,
        borderRadius: ChangePasswordScreenStyles.cardRadius,
        border: ChangePasswordScreenStyles.cardBorder,
        boxShadow: ChangePasswordScreenStyles.cardShadow,
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              ChangePasswordScreenStyles.formTitle,
              style: ChangePasswordScreenStyles.formTitleStyle,
            ),
            const SizedBox(
              height: ChangePasswordScreenStyles.formDescriptionSpacing,
            ),
            const Text(
              ChangePasswordScreenStyles.formDescription,
              style: ChangePasswordScreenStyles.formDescriptionStyle,
            ),
            const SizedBox(
              height: ChangePasswordScreenStyles.formFieldsSpacing,
            ),
            _PasswordField(
              controller: _currentPasswordController,
              focusNode: _currentPasswordFocus,
              label: ChangePasswordScreenStyles.currentPasswordLabel,
              hint: ChangePasswordScreenStyles.currentPasswordHint,
              prefixIcon: ChangePasswordScreenStyles.currentPasswordIcon,
              obscureText: !_showCurrentPassword,
              enabled: !_isSubmitting,
              validator: _validateCurrentPassword,
              textInputAction: TextInputAction.next,
              onVisibilityPressed: () {
                setState(() {
                  _showCurrentPassword = !_showCurrentPassword;
                });
              },
              onSubmitted: (_) {
                _newPasswordFocus.requestFocus();
              },
            ),
            const SizedBox(height: ChangePasswordScreenStyles.fieldSpacing),
            _PasswordField(
              controller: _newPasswordController,
              focusNode: _newPasswordFocus,
              label: ChangePasswordScreenStyles.newPasswordLabel,
              hint: ChangePasswordScreenStyles.newPasswordHint,
              prefixIcon: ChangePasswordScreenStyles.newPasswordIcon,
              obscureText: !_showNewPassword,
              enabled: !_isSubmitting,
              validator: _validateNewPassword,
              textInputAction: TextInputAction.next,
              inputFormatters: <TextInputFormatter>[
                LengthLimitingTextInputFormatter(128),
              ],
              onVisibilityPressed: () {
                setState(() {
                  _showNewPassword = !_showNewPassword;
                });
              },
              onSubmitted: (_) {
                _confirmPasswordFocus.requestFocus();
              },
            ),
            const SizedBox(height: ChangePasswordScreenStyles.fieldSpacing),
            _PasswordField(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocus,
              label: ChangePasswordScreenStyles.confirmPasswordLabel,
              hint: ChangePasswordScreenStyles.confirmPasswordHint,
              prefixIcon: ChangePasswordScreenStyles.confirmPasswordIcon,
              obscureText: !_showConfirmPassword,
              enabled: !_isSubmitting,
              validator: _validatePasswordConfirmation,
              textInputAction: TextInputAction.done,
              inputFormatters: <TextInputFormatter>[
                LengthLimitingTextInputFormatter(128),
              ],
              onVisibilityPressed: () {
                setState(() {
                  _showConfirmPassword = !_showConfirmPassword;
                });
              },
              onSubmitted: (_) {
                _submitPasswordChange();
              },
            ),
            const SizedBox(
              height: ChangePasswordScreenStyles.requirementsTopSpacing,
            ),
            const _PasswordRequirements(),
            const SizedBox(height: ChangePasswordScreenStyles.buttonTopSpacing),
            SizedBox(
              width: double.infinity,
              height: ChangePasswordScreenStyles.buttonHeight,
              child: FilledButton(
                style: ChangePasswordScreenStyles.submitButtonStyle,
                onPressed: _isSubmitting ? null : _submitPasswordChange,
                child: _isSubmitting
                    ? const SizedBox(
                        width: ChangePasswordScreenStyles.buttonProgressSize,
                        height: ChangePasswordScreenStyles.buttonProgressSize,
                        child: CircularProgressIndicator(
                          strokeWidth:
                              ChangePasswordScreenStyles.buttonProgressWidth,
                          color: ChangePasswordScreenStyles.surfaceColor,
                        ),
                      )
                    : const Text(
                        ChangePasswordScreenStyles.changePasswordLabel,
                        style: ChangePasswordScreenStyles.buttonTextStyle,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    required this.obscureText,
    required this.enabled,
    required this.validator,
    required this.textInputAction,
    required this.onVisibilityPressed,
    required this.onSubmitted,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  final String label;
  final String hint;
  final IconData prefixIcon;

  final bool obscureText;
  final bool enabled;

  final String? Function(String? value) validator;
  final TextInputAction textInputAction;
  final VoidCallback onVisibilityPressed;
  final ValueChanged<String> onSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: ChangePasswordScreenStyles.fieldLabelStyle),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          enabled: enabled,
          validator: validator,
          textInputAction: textInputAction,
          keyboardType: TextInputType.visiblePassword,
          enableSuggestions: false,
          autocorrect: false,
          inputFormatters: inputFormatters,
          style: ChangePasswordScreenStyles.fieldTextStyle,
          onFieldSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: ChangePasswordScreenStyles.fieldHintStyle,
            errorStyle: ChangePasswordScreenStyles.fieldErrorStyle,
            errorMaxLines: 2,
            filled: true,
            fillColor: ChangePasswordScreenStyles.surfaceColor,
            contentPadding: ChangePasswordScreenStyles.textFieldContentPadding,
            prefixIcon: Icon(
              prefixIcon,
              size: ChangePasswordScreenStyles.passwordIconSize,
              color: ChangePasswordScreenStyles.primaryColor,
            ),
            suffixIcon: IconButton(
              tooltip: obscureText ? 'Show password' : 'Hide password',
              onPressed: enabled ? onVisibilityPressed : null,
              icon: Icon(
                obscureText
                    ? ChangePasswordScreenStyles.passwordVisibleIcon
                    : ChangePasswordScreenStyles.passwordHiddenIcon,
                size: ChangePasswordScreenStyles.visibilityIconSize,
              ),
            ),
            enabledBorder: ChangePasswordScreenStyles.textFieldBorder(),
            disabledBorder: ChangePasswordScreenStyles.textFieldBorder(),
            focusedBorder: ChangePasswordScreenStyles.textFieldBorder(
              color: ChangePasswordScreenStyles.focusedOutlineColor,
              width: 1.5,
            ),
            errorBorder: ChangePasswordScreenStyles.textFieldBorder(
              color: ChangePasswordScreenStyles.errorColor,
            ),
            focusedErrorBorder: ChangePasswordScreenStyles.textFieldBorder(
              color: ChangePasswordScreenStyles.errorColor,
              width: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordRequirements extends StatelessWidget {
  const _PasswordRequirements();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ChangePasswordScreenStyles.requirementsPadding,
      decoration: BoxDecoration(
        color: ChangePasswordScreenStyles.primarySoftColor,
        borderRadius: ChangePasswordScreenStyles.requirementsRadius,
        border: Border.all(color: ChangePasswordScreenStyles.outlineColor),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            ChangePasswordScreenStyles.requirementsTitle,
            style: ChangePasswordScreenStyles.requirementsTitleStyle,
          ),
          SizedBox(height: ChangePasswordScreenStyles.requirementTitleSpacing),
          _RequirementRow(
            label: ChangePasswordScreenStyles.minimumLengthRequirement,
          ),
          SizedBox(height: ChangePasswordScreenStyles.requirementSpacing),
          _RequirementRow(
            label: ChangePasswordScreenStyles.maximumLengthRequirement,
          ),
          SizedBox(height: ChangePasswordScreenStyles.requirementSpacing),
          _RequirementRow(
            label: ChangePasswordScreenStyles.differentPasswordRequirement,
          ),
          SizedBox(height: ChangePasswordScreenStyles.requirementSpacing),
          _RequirementRow(
            label: ChangePasswordScreenStyles.matchingPasswordRequirement,
          ),
        ],
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(
          ChangePasswordScreenStyles.requirementIcon,
          size: ChangePasswordScreenStyles.requirementIconSize,
          color: ChangePasswordScreenStyles.primaryColor,
        ),
        const SizedBox(
          width: ChangePasswordScreenStyles.requirementContentSpacing,
        ),
        Expanded(
          child: Text(
            label,
            style: ChangePasswordScreenStyles.requirementStyle,
          ),
        ),
      ],
    );
  }
}

class _HeaderBrailleDecoration extends StatelessWidget {
  const _HeaderBrailleDecoration();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: ChangePasswordScreenStyles.decorationOpacity,
      child: SizedBox(
        width: ChangePasswordScreenStyles.decorationWidth,
        child: Wrap(
          spacing: ChangePasswordScreenStyles.decorationDotSpacing,
          runSpacing: ChangePasswordScreenStyles.decorationDotSpacing,
          children: List<Widget>.generate(
            ChangePasswordScreenStyles.decorationDotCount,
            (int index) {
              return const DecoratedBox(
                decoration: BoxDecoration(
                  color: ChangePasswordScreenStyles.surfaceColor,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: ChangePasswordScreenStyles.decorationDotSize,
                  height: ChangePasswordScreenStyles.decorationDotSize,
                ),
              );
            },
            growable: false,
          ),
        ),
      ),
    );
  }
}
