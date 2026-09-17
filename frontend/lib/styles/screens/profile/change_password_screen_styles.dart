import 'package:flutter/material.dart';

abstract final class ChangePasswordScreenStyles {
  // ============================================================
  // CONTENT
  // ============================================================

  static const String screenTitle = 'Change Password';

  static const String screenDescription =
      'Update the password used to securely access your TactileLens account.';

  static const String backTooltip = 'Return to Privacy & Security';

  static const String formTitle = 'Create a New Password';

  static const String formDescription =
      'Enter your current password before choosing a new one.';

  static const String currentPasswordLabel = 'Current password';
  static const String currentPasswordHint = 'Enter your current password';

  static const String newPasswordLabel = 'New password';
  static const String newPasswordHint = 'Enter your new password';

  static const String confirmPasswordLabel = 'Confirm new password';

  static const String confirmPasswordHint = 'Enter your new password again';

  static const String requirementsTitle = 'Password requirements';

  static const String minimumLengthRequirement =
      'Contains at least 8 characters';

  static const String maximumLengthRequirement =
      'Contains no more than 128 characters';

  static const String differentPasswordRequirement =
      'Different from your current password';

  static const String matchingPasswordRequirement =
      'New password and confirmation must match';

  static const String changePasswordLabel = 'Change Password';

  static const String currentPasswordRequired = 'Enter your current password.';

  static const String newPasswordRequired = 'Enter a new password.';

  static const String passwordTooShort =
      'The new password must contain at least 8 characters.';

  static const String passwordTooLong =
      'The new password cannot exceed 128 characters.';

  static const String samePasswordError =
      'The new password must be different from your current password.';

  static const String confirmationRequired = 'Confirm your new password.';

  static const String passwordsDoNotMatch = 'The new passwords do not match.';

  static const String sessionUnavailableMessage =
      'Your session is unavailable. Please sign in again.';

  static const String defaultErrorMessage =
      'Unable to change your password. Please try again.';

  static const String successTitle = 'Password Changed';

  static const String successDescription =
      'Your TactileLens password was changed successfully.';

  static const String doneLabel = 'Done';

  static const String googlePasswordTitle = 'Google-managed password';

  static const String googlePasswordDescription =
      'This account uses Google Sign-In. Manage your password through '
      'your Google Account.';

  static const String closeLabel = 'Close';

  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryColor = Color(0xFF1268F3);
  static const Color primaryDarkColor = Color(0xFF0758DD);
  static const Color primarySoftColor = Color(0xFFEDF4FF);

  static const Color backgroundColor = Color(0xFFF4F7FC);
  static const Color surfaceColor = Colors.white;

  static const Color textPrimaryColor = Color(0xFF10213D);
  static const Color textSecondaryColor = Color(0xFF42526B);
  static const Color textMutedColor = Color(0xFF728096);

  static const Color outlineColor = Color(0xFFDDE5F0);
  static const Color focusedOutlineColor = primaryColor;

  static const Color errorColor = Color(0xFFD14343);
  static const Color successColor = Color(0xFF16A765);
  static const Color successSoftColor = Color(0xFFE9F8F0);

  // ============================================================
  // ANIMATION
  // ============================================================

  static const Duration entranceDuration = Duration(milliseconds: 420);
  static const Duration entranceDelay = Duration(milliseconds: 100);
  static const Curve entranceCurve = Curves.easeOutCubic;
  static const Offset entranceBeginOffset = Offset(0, 0.025);

  static const Duration snackBarDuration = Duration(seconds: 4);

  // ============================================================
  // HEADER
  // ============================================================

  static const double headerHorizontalPadding = 14;
  static const double headerTopPadding = 12;
  static const double headerBottomPadding = 27;

  static const double headerBackSpacing = 5;
  static const double headerTextSpacing = 15;
  static const double headerDescriptionWidth = 285;

  static const EdgeInsets headerDescriptionPadding = EdgeInsets.symmetric(
    horizontal: 5,
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1474F5), Color(0xFF0758DD)],
  );

  static const BorderRadius headerRadius = BorderRadius.only(
    bottomLeft: Radius.elliptical(190, 34),
    bottomRight: Radius.elliptical(190, 34),
  );

  static const double decorationRight = 18;
  static const double decorationBottom = 22;
  static const double decorationOpacity = 0.18;
  static const double decorationWidth = 49;
  static const double decorationDotSize = 4;
  static const double decorationDotSpacing = 7;
  static const int decorationDotCount = 12;

  static const IconData backIcon = Icons.arrow_back_rounded;
  static const double backIconSize = 25;

  static final ButtonStyle backButtonStyle = IconButton.styleFrom(
    foregroundColor: surfaceColor,
    backgroundColor: const Color(0x26FFFFFF),
    shape: const CircleBorder(),
  );

  // ============================================================
  // LAYOUT AND CARD
  // ============================================================

  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(14, 18, 14, 32);

  static const EdgeInsets formCardPadding = EdgeInsets.all(18);

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(16));

  static const Border cardBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor, width: 1),
  );

  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x0D102A43), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const double formDescriptionSpacing = 6;
  static const double formFieldsSpacing = 20;
  static const double fieldSpacing = 15;

  // ============================================================
  // TEXT FIELDS
  // ============================================================

  static const double passwordIconSize = 21;
  static const double visibilityIconSize = 21;

  static const EdgeInsets textFieldContentPadding = EdgeInsets.symmetric(
    horizontal: 15,
    vertical: 16,
  );

  static const BorderRadius textFieldRadius = BorderRadius.all(
    Radius.circular(12),
  );

  static OutlineInputBorder textFieldBorder({
    Color color = outlineColor,
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: textFieldRadius,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  // ============================================================
  // REQUIREMENTS
  // ============================================================

  static const double requirementsTopSpacing = 18;

  static const EdgeInsets requirementsPadding = EdgeInsets.all(15);

  static const BorderRadius requirementsRadius = BorderRadius.all(
    Radius.circular(13),
  );

  static const double requirementTitleSpacing = 10;
  static const double requirementSpacing = 8;
  static const double requirementIconSize = 17;
  static const double requirementContentSpacing = 8;

  // ============================================================
  // BUTTON
  // ============================================================

  static const double buttonTopSpacing = 20;
  static const double buttonHeight = 52;

  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(13),
  );

  static const double buttonProgressSize = 22;
  static const double buttonProgressWidth = 2.4;

  static final ButtonStyle submitButtonStyle = FilledButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: surfaceColor,
    disabledBackgroundColor: const Color(0xFF9EC3FB),
    disabledForegroundColor: surfaceColor,
    shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
  );

  // ============================================================
  // DIALOG AND SNACKBAR
  // ============================================================

  static const BorderRadius dialogRadius = BorderRadius.all(
    Radius.circular(18),
  );

  static const EdgeInsets snackBarMargin = EdgeInsets.fromLTRB(16, 0, 16, 18);

  static const BorderRadius snackBarRadius = BorderRadius.all(
    Radius.circular(12),
  );

  // ============================================================
  // ICONS
  // ============================================================

  static const IconData currentPasswordIcon = Icons.lock_outline_rounded;
  static const IconData newPasswordIcon = Icons.password_rounded;
  static const IconData confirmPasswordIcon = Icons.verified_user_outlined;

  static const IconData passwordVisibleIcon = Icons.visibility_outlined;

  static const IconData passwordHiddenIcon = Icons.visibility_off_outlined;

  static const IconData requirementIcon = Icons.check_circle_outline_rounded;

  static const IconData successIcon = Icons.check_circle_rounded;
  static const IconData googleIcon = Icons.account_circle_outlined;

  // ============================================================
  // TYPOGRAPHY
  // ============================================================

  static const TextStyle headerTitleStyle = TextStyle(
    color: surfaceColor,
    fontSize: 21,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.25,
  );

  static const TextStyle headerDescriptionStyle = TextStyle(
    color: Color(0xFFE9F2FF),
    fontSize: 13.5,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle formTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle formDescriptionStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 13,
    height: 1.45,
  );

  static const TextStyle fieldLabelStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle fieldTextStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 14,
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

  static const TextStyle requirementsTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 13.5,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle requirementStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 12.5,
    height: 1.35,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    color: surfaceColor,
    fontSize: 14.5,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle dialogTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 19,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle dialogDescriptionStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 13.5,
    height: 1.45,
  );

  static const TextStyle snackBarTextStyle = TextStyle(
    color: surfaceColor,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
}
