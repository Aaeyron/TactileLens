import 'package:flutter/material.dart';

abstract final class ForgotPasswordScreenStyles {
  // ==========================
  // Content
  // ==========================

  static const String screenTitle = 'Reset your password';

  static const String screenDescription =
      'Recover your TactileLens password securely using your email.';

  static const String requestTitle = 'Find your account';

  static const String requestDescription =
      'Enter the email connected to your TactileLens password account.';

  static const String resetTitle = 'Check your email';

  static const String resetDescription =
      'Enter the six-digit code we sent, then create a new password.';

  static const String emailLabel = 'Email address';
  static const String emailHint = 'Enter your registered email';

  static const String resetCodeLabel = 'Reset code';
  static const String resetCodeHint = 'Enter the 6-digit code';

  static const String newPasswordLabel = 'New password';
  static const String newPasswordHint = 'Enter your new password';

  static const String confirmPasswordLabel = 'Confirm new password';
  static const String confirmPasswordHint = 'Enter your new password again';

  static const String sendCodeLabel = 'Send reset code';
  static const String resetPasswordLabel = 'Reset password';

  static const String changeEmailLabel = 'Use another email';
  static const String resendCodeLabel = 'Resend code';

  static const String backTooltip = 'Go back';
  static const String showPasswordTooltip = 'Show password';
  static const String hidePasswordTooltip = 'Hide password';

  static const String passwordRequirementsTitle = 'Password requirements';

  static const String passwordLengthRequirement =
      'Use between 8 and 128 characters.';

  static const String passwordMatchRequirement =
      'Both password entries must match.';

  // ==========================
  // Validation messages
  // ==========================

  static const String emailRequiredMessage =
      'Enter your registered email address.';

  static const String invalidEmailMessage = 'Enter a valid email address.';

  static const String resetCodeRequiredMessage =
      'Enter the reset code from your email.';

  static const String invalidResetCodeMessage =
      'The reset code must contain exactly six digits.';

  static const String newPasswordRequiredMessage = 'Enter your new password.';

  static const String passwordTooShortMessage =
      'Your password must contain at least 8 characters.';

  static const String passwordTooLongMessage =
      'Your password cannot exceed 128 characters.';

  static const String confirmationRequiredMessage =
      'Confirm your new password.';

  static const String passwordsDoNotMatchMessage =
      'The passwords do not match.';

  // ==========================
  // Response messages
  // ==========================

  static const String codeSentMessage =
      'If a password account exists for this email, a reset code will arrive shortly.';

  static const String codeResentMessage =
      'A new reset code has been requested. Check your email.';

  static const String passwordResetSuccessMessage =
      'Your password has been reset. You can now sign in with your new password.';

  static const String defaultRequestErrorMessage =
      'Unable to request a reset code. Please try again.';

  static const String defaultResetErrorMessage =
      'Unable to reset your password. Please try again.';

  static const String invalidResponseMessage =
      'The server returned an invalid response.';

  static const String connectionErrorMessage =
      'Unable to connect. Check your internet connection and try again.';

  static const String successDialogTitle = 'Password reset';

  static const String successDialogDescription =
      'Your new password is ready. Return to Sign In and use it to access your account.';

  static const String returnToSignInLabel = 'Return to Sign In';

  static String resendCountdownLabel(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  // ==========================
  // Colors
  // ==========================

  static const Color backgroundColor = Color(0xFFF5F8FE);
  static const Color surfaceColor = Colors.white;

  static const Color primaryColor = Color(0xFF0D47A1);
  static const Color brightPrimaryColor = Color(0xFF0969F9);
  static const Color darkPrimaryColor = Color(0xFF07357D);

  static const Color textPrimaryColor = Color(0xFF071633);
  static const Color textSecondaryColor = Color(0xFF566784);
  static const Color textMutedColor = Color(0xFF8795AE);

  static const Color outlineColor = Color(0xFFDCE6F5);
  static const Color disabledColor = Color(0xFFB8C3D5);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF16834A);

  static const Color iconBackgroundColor = Color(0xFFE8F1FF);
  static const Color informationBackgroundColor = Color(0xFFF0F6FF);

  // ==========================
  // Icons
  // ==========================

  static const IconData backIcon = Icons.arrow_back_ios_new_rounded;
  static const IconData recoveryIcon = Icons.lock_reset_rounded;
  static const IconData emailIcon = Icons.mail_outline_rounded;
  static const IconData resetCodeIcon = Icons.pin_outlined;
  static const IconData newPasswordIcon = Icons.password_rounded;
  static const IconData confirmPasswordIcon = Icons.verified_user_outlined;

  static const IconData passwordVisibleIcon = Icons.visibility_outlined;

  static const IconData passwordHiddenIcon = Icons.visibility_off_outlined;

  static const IconData requirementIcon = Icons.check_circle_outline_rounded;

  static const IconData successIcon = Icons.check_circle_rounded;
  static const IconData forwardIcon = Icons.arrow_forward_rounded;

  // ==========================
  // Layout
  // ==========================

  static const double maximumContentWidth = 560;

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(20, 16, 20, 28);

  static const EdgeInsets cardPadding = EdgeInsets.all(22);

  static const double headerTopSpacing = 8;
  static const double headerIconTopSpacing = 18;
  static const double headerIconSize = 68;
  static const double recoveryIconSize = 36;

  static const double titleTopSpacing = 18;
  static const double descriptionTopSpacing = 8;
  static const double cardTopSpacing = 28;

  static const double formDescriptionSpacing = 8;
  static const double formFieldsSpacing = 24;
  static const double fieldSpacing = 18;
  static const double labelFieldSpacing = 8;
  static const double buttonTopSpacing = 24;
  static const double secondaryActionSpacing = 12;

  static const double buttonHeight = 54;
  static const double buttonProgressSize = 22;
  static const double buttonProgressStrokeWidth = 2.5;
  static const double fieldIconSize = 21;

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(22));

  static const BorderRadius iconRadius = BorderRadius.all(Radius.circular(20));

  static const BorderRadius fieldRadius = BorderRadius.all(Radius.circular(14));

  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(14),
  );

  static const BorderRadius dialogRadius = BorderRadius.all(
    Radius.circular(20),
  );

  static const BorderSide cardBorder = BorderSide(color: outlineColor);

  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x14104480), blurRadius: 22, offset: Offset(0, 8)),
  ];

  static const EdgeInsets fieldContentPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 17,
  );

  static const EdgeInsets snackBarMargin = EdgeInsets.fromLTRB(16, 0, 16, 18);

  static const BorderRadius snackBarRadius = BorderRadius.all(
    Radius.circular(12),
  );

  static const Duration snackBarDuration = Duration(seconds: 4);
  static const Duration resendCooldown = Duration(seconds: 60);

  // ==========================
  // Typography
  // ==========================

  static const TextStyle screenTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 27,
    height: 1.15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
  );

  static const TextStyle screenDescriptionStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle formTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 19,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle formDescriptionStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 13.5,
    height: 1.45,
  );

  static const TextStyle fieldLabelStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle fieldTextStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 14.5,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle fieldHintStyle = TextStyle(
    color: textMutedColor,
    fontSize: 13.5,
  );

  static const TextStyle fieldErrorStyle = TextStyle(
    color: errorColor,
    fontSize: 11.5,
    height: 1.25,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    color: surfaceColor,
    fontSize: 14.5,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle secondaryButtonTextStyle = TextStyle(
    color: brightPrimaryColor,
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle informationTextStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 12.5,
    height: 1.45,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle requirementsTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 13,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle requirementTextStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 12.5,
    height: 1.4,
  );

  static const TextStyle dialogTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 19,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle dialogDescriptionStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 13.5,
    height: 1.5,
  );

  static const TextStyle snackBarTextStyle = TextStyle(
    color: surfaceColor,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  // ==========================
  // Input decoration
  // ==========================

  static const OutlineInputBorder enabledFieldBorder = OutlineInputBorder(
    borderRadius: fieldRadius,
    borderSide: BorderSide(color: outlineColor, width: 1.2),
  );

  static const OutlineInputBorder focusedFieldBorder = OutlineInputBorder(
    borderRadius: fieldRadius,
    borderSide: BorderSide(color: brightPrimaryColor, width: 1.6),
  );

  static const OutlineInputBorder errorFieldBorder = OutlineInputBorder(
    borderRadius: fieldRadius,
    borderSide: BorderSide(color: errorColor, width: 1.2),
  );

  static const OutlineInputBorder disabledFieldBorder = OutlineInputBorder(
    borderRadius: fieldRadius,
    borderSide: BorderSide(color: outlineColor),
  );

  static InputDecoration fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: fieldHintStyle,
      prefixIcon: Icon(icon, color: brightPrimaryColor, size: fieldIconSize),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: surfaceColor,
      contentPadding: fieldContentPadding,
      enabledBorder: enabledFieldBorder,
      focusedBorder: focusedFieldBorder,
      errorBorder: errorFieldBorder,
      focusedErrorBorder: errorFieldBorder,
      disabledBorder: disabledFieldBorder,
      border: enabledFieldBorder,
      errorStyle: fieldErrorStyle,
    );
  }

  // ==========================
  // Buttons
  // ==========================

  static final ButtonStyle backButtonStyle = IconButton.styleFrom(
    foregroundColor: textPrimaryColor,
    disabledForegroundColor: disabledColor,
  );

  static final ButtonStyle primaryButtonStyle = FilledButton.styleFrom(
    backgroundColor: brightPrimaryColor,
    foregroundColor: surfaceColor,
    disabledBackgroundColor: brightPrimaryColor.withValues(alpha: 0.55),
    disabledForegroundColor: surfaceColor,
    elevation: 4,
    shadowColor: const Color(0x331B65E9),
    padding: const EdgeInsets.symmetric(horizontal: 18),
    shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
  );

  static final ButtonStyle secondaryButtonStyle = TextButton.styleFrom(
    foregroundColor: brightPrimaryColor,
    disabledForegroundColor: disabledColor,
    textStyle: secondaryButtonTextStyle,
  );

  static final ButtonStyle dialogButtonStyle = FilledButton.styleFrom(
    backgroundColor: brightPrimaryColor,
    foregroundColor: surfaceColor,
    shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
  );
}
