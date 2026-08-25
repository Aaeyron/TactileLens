import 'package:flutter/material.dart';

abstract final class SignInStyles {
  // ==========================
  // Content
  // ==========================

  static const String logoAsset = 'assets/icons/tactilelens_app_icon.png';

  static const String logoSemanticLabel = 'TactileLens application logo';

  static const String title = 'Welcome back!';

  static const String descriptionFirstPart = 'Sign in to continue using ';

  static const String appName = 'TactileLens';
  static const String descriptionLastPart = '.';

  static const String emailLabel = 'Email';
  static const String emailHint = 'Enter your email';

  static const String passwordLabel = 'Password';
  static const String passwordHint = 'Enter your password';

  static const String forgotPasswordLabel = 'Forgot password?';

  static const String signInLabel = 'Sign In';
  static const String signingInLabel = 'Signing In...';

  static const String orLabel = 'or';

  static const String googleIconLetter = 'G';
  static const String googleLabel = 'Sign in with Google';

  static const String noAccountLabel = "Don't have an account?";

  static const String signUpLabel = 'Sign Up';

  static const String guestLabel = 'Continue without an account';

  static const String backTooltip = 'Go back';
  static const String showPasswordTooltip = 'Show password';

  static const String hidePasswordTooltip = 'Hide password';

  static const String aiLabel = 'AI';

  // ==========================
  // Messages
  // ==========================

  static const String emptyFieldsMessage = 'Please fill in all fields.';

  static const String defaultSignInError =
      'Unable to sign in. Please try again.';

  static const String invalidUserMessage =
      'The server returned invalid user information.';

  static const String missingTokenMessage =
      'The server did not return an authentication token.';

  static const String invalidUserIdMessage =
      'The server returned an invalid user ID.';

  static const String incompleteUserMessage =
      'The server returned incomplete user information.';

  static const String invalidResponseMessage =
      'The server returned an invalid response.';

  static const String connectionErrorMessage =
      'Unable to sign in. Check your connection and try again.';

  static const String loginSuccessMessage = 'Login successful!';

  // ==========================
  // Colors
  // ==========================

  static const Color backgroundColor = Color(0xFFF9FBFF);
  static const Color primaryColor = Color(0xFF0D47A1);
  static const Color brightPrimaryColor = Color(0xFF0969F9);
  static const Color darkTitleColor = Color(0xFF061541);
  static const Color descriptionColor = Color(0xFF53658C);
  static const Color fieldHintColor = Color(0xFF8492B2);
  static const Color fieldSuffixIconColor = Color(0xFF7F8EAE);

  static const Color surfaceColor = Colors.white;
  static const Color dividerColor = Color(0xFFD4E2F7);
  static const Color outlineColor = Color(0xFFDCE6F7);
  static const Color forwardIconColor = Color(0xFF7F96C2);
  static const Color guestBackgroundColor = Color(0xFFF1F6FF);

  static const Color decorationDotColor = Color(0xFFDCEAFF);

  static const Color illustrationColor = Color(0xFF73A6FF);

  static const Color illustrationBackgroundColor = Color(0xFFF1F6FF);

  // ==========================
  // Icons
  // ==========================

  static const IconData backIcon = Icons.arrow_back_ios_new_rounded;

  static const IconData emailIcon = Icons.mail_outline_rounded;

  static const IconData passwordIcon = Icons.lock_outline_rounded;

  static const IconData visiblePasswordIcon = Icons.visibility_outlined;

  static const IconData hiddenPasswordIcon = Icons.visibility_off_outlined;

  static const IconData signInIcon = Icons.person_outline_rounded;

  static const IconData guestIcon = Icons.login_rounded;

  static const IconData forwardIcon = Icons.chevron_right_rounded;

  static const IconData illustrationBookIcon = Icons.menu_book_rounded;

  // ==========================
  // Screen layout
  // ==========================

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 16,
  );

  static const double logoTopSpacing = 12;
  static const double logoContainerSize = 112;

  static const EdgeInsets logoPadding = EdgeInsets.all(13);

  static const double logoBottomSpacing = 22;
  static const double descriptionSpacing = 9;
  static const double formTopSpacing = 31;
  static const double fieldSpacing = 18;
  static const double labelFieldSpacing = 8;
  static const double signInTopSpacing = 4;
  static const double dividerSpacing = 18;
  static const double signUpTopSpacing = 15;
  static const double guestTopSpacing = 2;
  static const double bottomIllustrationSpacing = 28;

  // ==========================
  // Logo
  // ==========================

  static const BorderRadius logoRadius = BorderRadius.all(Radius.circular(28));

  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF4878FF), Color(0xFF153AB8)],
  );

  static const List<BoxShadow> logoShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x2B1C64E8),
      blurRadius: 24,
      spreadRadius: 1,
      offset: Offset(0, 10),
    ),
  ];

  // ==========================
  // Typography
  // ==========================

  static const TextStyle titleStyle = TextStyle(
    color: darkTitleColor,
    fontSize: 29,
    height: 1.15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const TextStyle descriptionStyle = TextStyle(
    color: descriptionColor,
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle descriptionHighlightStyle = TextStyle(
    color: brightPrimaryColor,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle fieldLabelStyle = TextStyle(
    color: darkTitleColor,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle inputTextStyle = TextStyle(
    color: darkTitleColor,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle primaryButtonTextStyle = TextStyle(
    color: surfaceColor,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle googleButtonTextStyle = TextStyle(
    color: darkTitleColor,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle googleIconStyle = TextStyle(
    color: Color(0xFF4285F4),
    fontSize: 22,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle accountPromptStyle = TextStyle(
    color: descriptionColor,
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle guestButtonTextStyle = TextStyle(
    color: darkTitleColor,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle orLabelStyle = TextStyle(
    color: descriptionColor,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle snackBarTextStyle = TextStyle(
    color: surfaceColor,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle illustrationAiStyle = TextStyle(
    color: illustrationColor,
    fontSize: 20,
    fontWeight: FontWeight.w800,
  );

  // ==========================
  // Input fields
  // ==========================

  static const double fieldIconSize = 21;

  static const EdgeInsets fieldContentPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 17,
  );

  static const BorderRadius fieldRadius = BorderRadius.all(Radius.circular(14));

  static const OutlineInputBorder enabledFieldBorder = OutlineInputBorder(
    borderRadius: fieldRadius,
    borderSide: BorderSide(color: outlineColor, width: 1.2),
  );

  static const OutlineInputBorder focusedFieldBorder = OutlineInputBorder(
    borderRadius: fieldRadius,
    borderSide: BorderSide(color: brightPrimaryColor, width: 1.6),
  );

  static const OutlineInputBorder disabledFieldBorder = OutlineInputBorder(
    borderRadius: fieldRadius,
    borderSide: BorderSide(color: dividerColor, width: 1),
  );

  static const InputDecoration emailDecoration = InputDecoration(
    hintText: emailHint,
    hintStyle: TextStyle(color: fieldHintColor, fontSize: 14),
    prefixIcon: Icon(emailIcon, color: brightPrimaryColor, size: fieldIconSize),
    filled: true,
    fillColor: surfaceColor,
    contentPadding: fieldContentPadding,
    enabledBorder: enabledFieldBorder,
    focusedBorder: focusedFieldBorder,
    disabledBorder: disabledFieldBorder,
    border: enabledFieldBorder,
  );

  static const InputDecoration passwordDecoration = InputDecoration(
    hintText: passwordHint,
    hintStyle: TextStyle(color: fieldHintColor, fontSize: 14),
    prefixIcon: Icon(
      passwordIcon,
      color: brightPrimaryColor,
      size: fieldIconSize,
    ),
    filled: true,
    fillColor: surfaceColor,
    contentPadding: fieldContentPadding,
    enabledBorder: enabledFieldBorder,
    focusedBorder: focusedFieldBorder,
    disabledBorder: disabledFieldBorder,
    border: enabledFieldBorder,
  );

  // ==========================
  // Buttons
  // ==========================

  static const double buttonHeight = 54;
  static const double buttonIconSize = 21;
  static const double backIconSize = 22;
  static const double forwardIconSize = 24;
  static const double loadingIndicatorSize = 22;
  static const double loadingStrokeWidth = 2.5;
  static const double googleIconSpacing = 14;

  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(14),
  );

  static final ButtonStyle backButtonStyle = IconButton.styleFrom(
    foregroundColor: darkTitleColor,
    disabledForegroundColor: fieldHintColor,
  );

  static final ButtonStyle signInButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: brightPrimaryColor,
    foregroundColor: surfaceColor,
    disabledBackgroundColor: brightPrimaryColor.withValues(alpha: 0.55),
    disabledForegroundColor: surfaceColor,
    elevation: 6,
    shadowColor: const Color(0x401B65E9),
    padding: const EdgeInsets.symmetric(horizontal: 18),
    shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
  );

  static final ButtonStyle googleButtonStyle = OutlinedButton.styleFrom(
    backgroundColor: surfaceColor,
    disabledBackgroundColor: surfaceColor,
    foregroundColor: darkTitleColor,
    disabledForegroundColor: darkTitleColor,
    elevation: 4,
    shadowColor: const Color(0x241B65E9),
    padding: const EdgeInsets.symmetric(horizontal: 18),
    side: const BorderSide(color: outlineColor, width: 1.2),
    shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
  );

  static final ButtonStyle guestButtonStyle = OutlinedButton.styleFrom(
    backgroundColor: guestBackgroundColor,
    foregroundColor: brightPrimaryColor,
    disabledBackgroundColor: guestBackgroundColor,
    disabledForegroundColor: fieldHintColor,
    elevation: 3,
    shadowColor: const Color(0x1F1B65E9),
    padding: const EdgeInsets.symmetric(horizontal: 18),
    side: const BorderSide(color: Color(0xFFE0EAFB), width: 1),
    shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
  );

  static final ButtonStyle forgotPasswordButtonStyle = TextButton.styleFrom(
    foregroundColor: brightPrimaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
  );

  static final ButtonStyle signUpLinkButtonStyle = TextButton.styleFrom(
    foregroundColor: brightPrimaryColor,
    padding: const EdgeInsets.only(left: 4),
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
  );

  // ==========================
  // Divider
  // ==========================

  static const double dividerThickness = 1;

  static const EdgeInsets orLabelPadding = EdgeInsets.symmetric(horizontal: 18);

  // ==========================
  // Background decoration
  // ==========================

  static const double topDecorationSize = 260;
  static const double bottomDecorationSize = 310;
  static const double topDecorationOffset = -135;
  static const double bottomDecorationOffset = -175;

  static const double leftDotsTop = 110;
  static const double rightDotsTop = 235;
  static const double dotsSideOffset = 12;

  static const int decorationDotCount = 6;
  static const double decorationDotSize = 6;
  static const double decorationDotSpacing = 9;

  static const LinearGradient backgroundDecorationGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFDDEAFF), Color(0xFFF3F7FF)],
  );

  static const List<BoxShadow> decorationDotShadow = <BoxShadow>[
    BoxShadow(color: Color(0x1F1769E8), blurRadius: 4, offset: Offset(0, 2)),
  ];

  // ==========================
  // Bottom illustration
  // ==========================

  static const double illustrationWidth = 122;
  static const double illustrationHeight = 88;
  static const double illustrationBookSize = 82;
  static const double illustrationBadgeSize = 54;
  static const double illustrationBorderWidth = 3;

  // ==========================
  // Snack bar
  // ==========================

  static const Duration snackBarDuration = Duration(seconds: 3);

  static const EdgeInsets snackBarMargin = EdgeInsets.all(16);

  static const BorderRadius snackBarRadius = BorderRadius.all(
    Radius.circular(14),
  );

  // ==========================
  // Google account dialog
  // ==========================

  static const String googleAccountDialogTitle = 'Use Google to sign in';

  static const String googleAccountDialogMessage =
      'This account was created with Google. Continue with Google to securely access your TactileLens account.';

  static const String continueWithGoogleLabel = 'Continue with Google';

  static const String cancelLabel = 'Cancel';

  static const Color accountDialogIconBackgroundColor = Color(0xFFEAF2FF);

  static const IconData googleAccountIcon = Icons.g_mobiledata_rounded;

  static const TextStyle accountDialogTitleStyle = TextStyle(
    color: darkTitleColor,
    fontSize: 19,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle accountDialogMessageStyle = TextStyle(
    color: descriptionColor,
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle accountDialogGoogleIconStyle = TextStyle(
    color: surfaceColor,
    fontSize: 19,
    fontWeight: FontWeight.w900,
  );

  static const BorderRadius accountDialogRadius = BorderRadius.all(
    Radius.circular(22),
  );

  static const EdgeInsets accountDialogTitlePadding = EdgeInsets.fromLTRB(
    24,
    24,
    24,
    12,
  );

  static const EdgeInsets accountDialogContentPadding = EdgeInsets.fromLTRB(
    24,
    0,
    24,
    20,
  );

  static const EdgeInsets accountDialogActionsPadding = EdgeInsets.fromLTRB(
    16,
    0,
    16,
    16,
  );

  static const double accountDialogIconContainerSize = 44;
  static const double accountDialogIconSize = 30;
  static const double accountDialogIconSpacing = 12;

  static final ButtonStyle accountDialogCancelButtonStyle =
      TextButton.styleFrom(
        foregroundColor: descriptionColor,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      );

  static final ButtonStyle accountDialogGoogleButtonStyle =
      ElevatedButton.styleFrom(
        backgroundColor: brightPrimaryColor,
        foregroundColor: surfaceColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      );
}
