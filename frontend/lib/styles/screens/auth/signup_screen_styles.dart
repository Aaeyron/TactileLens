import 'package:flutter/material.dart';

abstract final class SignUpStyles {
  // ==========================
  // Content
  // ==========================

  static const String logoAsset = 'assets/icons/tactilelens_app_icon.png';

  static const String logoSemanticLabel = 'TactileLens application logo';

  static const String titleFirstPart = 'Create your ';
  static const String titleHighlightedPart = 'account';

  static const String descriptionFirstPart = 'Join ';
  static const String appName = 'TactileLens';

  static const String descriptionLastPart =
      ' and start transforming\n'
      'printed materials into accessible learning.';

  static const String firstNameLabel = 'First name';
  static const String firstNameHint = 'Enter your first name';

  static const String lastNameLabel = 'Last name';
  static const String lastNameHint = 'Enter your last name';

  static const String emailLabel = 'Email Address';
  static const String emailHint = 'Enter your email address';

  static const String passwordLabel = 'Password';
  static const String passwordHint = 'Create a password';

  static const String confirmPasswordLabel = 'Confirm Password';

  static const String confirmPasswordHint = 'Confirm your password';

  static const String passwordRequirement =
      'At least 8 characters with a number and a symbol';

  static const String roleLabel = 'Role';

  static const String studentRole = 'Student';
  static const String studentTitle = 'Student';

  static const String studentDescription =
      'Access learning materials and personal tools.';

  static const String educatorRole = 'Educator';
  static const String educatorTitle = 'Educator';

  static const String educatorDescription =
      'Create, manage, and share learning materials.';

  static const String signUpLabel = 'Sign Up';
  static const String orLabel = 'or';

  static const String googleIconLetter = 'G';
  static const String googleLabel = 'Continue with Google';

  static const String hasAccountLabel = 'Already have an account?';

  static const String signInLabel = 'Sign In';

  static const String backTooltip = 'Go back';

  static const String showPasswordTooltip = 'Show password';

  static const String hidePasswordTooltip = 'Hide password';

  // ==========================
  // Messages
  // ==========================

  static const String emptyFieldsMessage = 'Please fill in all fields.';

  static const String invalidEmailMessage =
      'Please enter a valid email address.';

  static const String passwordMismatchMessage = 'Passwords do not match.';

  static const String accountCreatedMessage = 'Account created successfully!';

  static const String emailExistsMessage = 'This email is already registered.';

  static const String registrationFailedMessage =
      'Registration failed. Please try again.';

  static const String connectionErrorMessage =
      'Unable to register. Check your connection and try again.';

  static const String googleAuthenticationFailedMessage =
      'Unable to continue with Google. Please try again.';

  static const String invalidGoogleResponseMessage =
      'Google authentication completed, but the account information could not be processed.';

  static const String googleConnectionErrorMessage =
      'Unable to contact Google or the TactileLens server. Check your connection and try again.';

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
  static const Color outlineColor = Color(0xFFDCE6F7);
  static const Color dividerColor = Color(0xFFD4E2F7);

  static const Color selectedRoleBackground = Color(0xFFF2F7FF);

  static const Color selectedRoleIconBackground = Color(0xFFDCEAFF);

  static const Color unselectedRoleIconBackground = Color(0xFFE7F8EE);

  static const Color educatorColor = Color(0xFF35B96F);

  static const Color unselectedRoleCircleColor = Color(0xFFB7C4DC);

  static const Color decorationDotColor = Color(0xFFDCEAFF);

  static const Color illustrationColor = Color(0xFF78A9FF);

  // ==========================
  // Icons
  // ==========================

  static const IconData backIcon = Icons.arrow_back_ios_new_rounded;

  static const IconData personIcon = Icons.person_outline_rounded;

  static const IconData emailIcon = Icons.mail_outline_rounded;

  static const IconData passwordIcon = Icons.lock_outline_rounded;

  static const IconData visiblePasswordIcon = Icons.visibility_outlined;

  static const IconData hiddenPasswordIcon = Icons.visibility_off_outlined;

  static const IconData studentIcon = Icons.school_outlined;

  static const IconData educatorIcon = Icons.co_present_outlined;

  static const IconData signUpIcon = Icons.person_add_alt_1_outlined;

  static const IconData forwardIcon = Icons.chevron_right_rounded;

  static const IconData illustrationIcon = Icons.menu_book_rounded;

  // ==========================
  // Screen layout
  // ==========================

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 14,
  );

  static const double logoTopSpacing = 5;
  static const double logoContainerSize = 100;

  static const EdgeInsets logoPadding = EdgeInsets.all(12);

  static const double logoBottomSpacing = 18;
  static const double descriptionSpacing = 8;
  static const double formTopSpacing = 24;
  static const double fieldSpacing = 15;
  static const double labelFieldSpacing = 7;
  static const double passwordHelpSpacing = 7;
  static const double roleTopSpacing = 17;
  static const double roleCardsSpacing = 9;
  static const double signUpTopSpacing = 20;
  static const double dividerSpacing = 17;
  static const double signInPromptSpacing = 15;
  static const double illustrationSpacing = 21;
  static const double bottomSpacing = 20;

  // ==========================
  // Logo
  // ==========================

  static const BorderRadius logoRadius = BorderRadius.all(Radius.circular(25));

  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF4878FF), Color(0xFF153AB8)],
  );

  static const List<BoxShadow> logoShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x2B1C64E8),
      blurRadius: 22,
      spreadRadius: 1,
      offset: Offset(0, 9),
    ),
  ];

  // ==========================
  // Typography
  // ==========================

  static const TextStyle titleDarkStyle = TextStyle(
    color: darkTitleColor,
    fontSize: 26,
    height: 1.15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
  );

  static const TextStyle titleBlueStyle = TextStyle(
    color: brightPrimaryColor,
    fontSize: 26,
    height: 1.15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
  );

  static const TextStyle descriptionStyle = TextStyle(
    color: descriptionColor,
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle descriptionHighlightStyle = TextStyle(
    color: brightPrimaryColor,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle fieldLabelStyle = TextStyle(
    color: darkTitleColor,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle inputTextStyle = TextStyle(
    color: darkTitleColor,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle passwordHelpStyle = TextStyle(
    color: descriptionColor,
    fontSize: 10.5,
    height: 1.25,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle roleTitleStyle = TextStyle(
    color: darkTitleColor,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle roleDescriptionStyle = TextStyle(
    color: descriptionColor,
    fontSize: 8.5,
    height: 1.25,
    fontWeight: FontWeight.w400,
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
    fontSize: 13,
    fontWeight: FontWeight.w400,
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

  // ==========================
  // Input fields
  // ==========================

  static const double fieldIconSize = 20;

  static const EdgeInsets fieldContentPadding = EdgeInsets.symmetric(
    horizontal: 15,
    vertical: 14,
  );

  static const BorderRadius fieldRadius = BorderRadius.all(Radius.circular(13));

  static const OutlineInputBorder enabledFieldBorder = OutlineInputBorder(
    borderRadius: fieldRadius,
    borderSide: BorderSide(color: outlineColor, width: 1.1),
  );

  static const OutlineInputBorder focusedFieldBorder = OutlineInputBorder(
    borderRadius: fieldRadius,
    borderSide: BorderSide(color: brightPrimaryColor, width: 1.6),
  );

  static const OutlineInputBorder disabledFieldBorder = OutlineInputBorder(
    borderRadius: fieldRadius,
    borderSide: BorderSide(color: dividerColor, width: 1),
  );

  static const InputDecoration firstNameDecoration = InputDecoration(
    hintText: firstNameHint,
    hintStyle: TextStyle(color: fieldHintColor, fontSize: 13),
    prefixIcon: Icon(
      personIcon,
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

  static const InputDecoration lastNameDecoration = InputDecoration(
    hintText: lastNameHint,
    hintStyle: TextStyle(color: fieldHintColor, fontSize: 13),
    prefixIcon: Icon(
      personIcon,
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

  static const InputDecoration emailDecoration = InputDecoration(
    hintText: emailHint,
    hintStyle: TextStyle(color: fieldHintColor, fontSize: 13),
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
    hintStyle: TextStyle(color: fieldHintColor, fontSize: 13),
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

  static const InputDecoration confirmPasswordDecoration = InputDecoration(
    hintText: confirmPasswordHint,
    hintStyle: TextStyle(color: fieldHintColor, fontSize: 13),
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
  // Role cards
  // ==========================

  static const double roleCardGap = 12;
  static const double roleCardHeight = 98;
  static const double roleBorderWidth = 1;
  static const double selectedRoleBorderWidth = 1.5;

  static const EdgeInsets roleCardPadding = EdgeInsets.all(12);

  static const BorderRadius roleCardRadius = BorderRadius.all(
    Radius.circular(14),
  );

  static const double roleIconContainerSize = 42;
  static const double roleIconSize = 23;
  static const double roleContentSpacing = 9;
  static const double roleDescriptionSpacing = 4;
  static const double roleSelectionSize = 18;
  static const double roleSelectionBorderWidth = 1.5;
  static const double roleCheckIconSize = 13;

  static const Duration roleAnimationDuration = Duration(milliseconds: 180);

  static const List<BoxShadow> roleCardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x141B65E9), blurRadius: 12, offset: Offset(0, 5)),
  ];

  // ==========================
  // Buttons
  // ==========================

  static const double buttonHeight = 52;
  static const double buttonIconSize = 20;
  static const double backIconSize = 22;
  static const double forwardIconSize = 23;
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

  static final ButtonStyle signUpButtonStyle = ElevatedButton.styleFrom(
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

  static final ButtonStyle signInLinkButtonStyle = TextButton.styleFrom(
    foregroundColor: brightPrimaryColor,
    padding: const EdgeInsets.only(left: 4),
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
  );

  // ==========================
  // Divider
  // ==========================

  static const double dividerThickness = 1;

  static const EdgeInsets orLabelPadding = EdgeInsets.symmetric(horizontal: 18);

  // ==========================
  // Background decoration
  // ==========================

  static const double topDecorationSize = 250;
  static const double bottomDecorationSize = 320;
  static const double topDecorationOffset = -135;
  static const double bottomDecorationOffset = -185;

  static const double leftDotsTop = 55;
  static const double rightDotsTop = 60;
  static const double dotsSideOffset = 47;

  static const int decorationDotRows = 3;
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

  static const double illustrationSize = 88;

  // ==========================
  // Snack bar
  // ==========================

  static const Duration snackBarDuration = Duration(seconds: 3);

  static const EdgeInsets snackBarMargin = EdgeInsets.all(16);

  static const BorderRadius snackBarRadius = BorderRadius.all(
    Radius.circular(14),
  );
}
