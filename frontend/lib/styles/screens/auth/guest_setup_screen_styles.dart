import 'package:flutter/material.dart';

abstract final class GuestStyles {
  // ==========================================================
  // CONTENT
  // ==========================================================

  static const String logoAsset =
      'assets/icons/tactilelens_app_icon.png';

  static const String logoSemanticLabel = 'TactileLens logo';

  static const String title = 'Almost there!';

  static const String description =
      'Let’s set up a few details to personalize your '
      'TactileLens experience.';

  static const String offlineTitle = 'Offline guest mode';

  static const String offlineDescription =
      'Your guest profile and saved materials will stay only '
      'on this device. Sign in later to sync and back up your data.';

  static const String nicknameLabel = 'Nickname';
  static const String nicknameHint = 'Enter your nickname';

  static const String nicknameHelper =
      'This is how you will be identified in the app.';

  static const String roleLabel = 'Role';

  static const String roleDescription =
      'Choose the role that best describes you.';

  static const String studentLabel = 'Student';

  static const String studentDescription =
      'Access learning materials and personal tools.';

  static const String educatorLabel = 'Educator';

  static const String educatorDescription =
      'Create, manage, and share learning materials.';

  static const String continueLabel = 'Continue';

  static const String nicknameRequiredMessage =
      'Please enter your nickname.';

  static const String guestSetupErrorMessage =
      'Guest setup could not be completed. Please try again.';

  static const String backTooltip = 'Go back';

  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color backgroundColor = Color(0xFFF8FBFF);
  static const Color surfaceColor = Colors.white;

  static const Color primaryColor = Color(0xFF1268F3);
  static const Color primaryDarkColor = Color(0xFF0D47A1);
  static const Color primarySoftColor = Color(0xFFEAF2FF);

  static const Color titleColor = Color(0xFF09194F);
  static const Color bodyColor = Color(0xFF53648F);
  static const Color mutedColor = Color(0xFF8C9ABE);
  static const Color outlineColor = Color(0xFFD8E3F8);

  static const Color educatorColor = Color(0xFF22B45E);
  static const Color educatorSoftColor = Color(0xFFEAF8EF);

  static const Color selectedRoleBackground =
      Color(0xFFF2F7FF);

  static const Color unselectedRoleCircleColor =
      Color(0xFFB7C4DC);

  static const Color offlineBackgroundColor =
      Color(0xFFEDF5FF);

  static const Color offlineBorderColor =
      Color(0xFFC9DEFF);

  static const Color decorationColor = Color(0xFFD7E7FF);
  static const Color decorationLightColor =
      Color(0xFFEBF3FF);

  static const Color whiteColor = Colors.white;

  // ==========================================================
  // SCREEN LAYOUT
  // ==========================================================

  static const double screenHorizontalPadding = 24;
  static const double screenVerticalPadding = 18;

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: screenHorizontalPadding,
    vertical: screenVerticalPadding,
  );

  static const double backButtonSize = 46;
  static const double backIconSize = 29;

  // ==========================================================
  // LOGO
  // ==========================================================

  static const double logoContainerSize = 100;

  static const EdgeInsets logoPadding = EdgeInsets.all(12);

  static const BorderRadius logoRadius = BorderRadius.all(
    Radius.circular(25),
  );

  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF4878FF),
      Color(0xFF153AB8),
    ],
  );

  static const List<BoxShadow> logoShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x2B1C64E8),
      blurRadius: 22,
      spreadRadius: 1,
      offset: Offset(0, 9),
    ),
  ];

  // ==========================================================
  // SPACING
  // ==========================================================

  static const double titleTopSpacing = 28;
  static const double descriptionTopSpacing = 10;
  static const double offlineTopSpacing = 22;
  static const double sectionTopSpacing = 28;

  static const double smallSpacing = 8;
  static const double itemSpacing = 14;

  // ==========================================================
  // OFFLINE NOTICE
  // ==========================================================

  static const EdgeInsets offlineNoticePadding =
      EdgeInsets.all(16);

  static const BorderRadius offlineNoticeRadius =
      BorderRadius.all(
        Radius.circular(18),
      );

  static const BoxDecoration offlineNoticeDecoration =
      BoxDecoration(
        color: offlineBackgroundColor,
        borderRadius: offlineNoticeRadius,
        border: Border.fromBorderSide(
          BorderSide(color: offlineBorderColor),
        ),
      );

  // ==========================================================
  // NICKNAME FIELD
  // ==========================================================

  static const double sectionIconSize = 27;
  static const double inputIconSize = 24;
  static const double inputHeight = 62;

  static const int nicknameMaximumLength = 40;

  static const EdgeInsets inputContentPadding =
      EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      );

  static const BorderRadius inputRadius = BorderRadius.all(
    Radius.circular(16),
  );

  // ==========================================================
  // ROLE CARDS
  // ==========================================================

  static const double roleCardHeight = 102;
  static const double roleCardGap = 12;

  static const double roleBorderWidth = 1;
  static const double selectedRoleBorderWidth = 1.5;

  static const EdgeInsets roleCardPadding =
      EdgeInsets.all(12);

  static const BorderRadius roleCardRadius =
      BorderRadius.all(
        Radius.circular(14),
      );

  static const double roleIconContainerSize = 42;
  static const double roleIconSize = 23;
  static const double roleContentSpacing = 9;
  static const double roleDescriptionSpacing = 4;

  static const double roleSelectionSize = 18;
  static const double roleSelectionBorderWidth = 1.5;
  static const double roleCheckIconSize = 13;
  static const double roleSelectionOffset = 0;

  static const Duration roleAnimationDuration =
      Duration(milliseconds: 180);

  static const List<BoxShadow> roleCardShadow =
      <BoxShadow>[
        BoxShadow(
          color: Color(0x141B65E9),
          blurRadius: 12,
          offset: Offset(0, 5),
        ),
      ];

  // ==========================================================
  // CONTINUE BUTTON
  // ==========================================================

  static const double buttonHeight = 58;
  static const double buttonIconSize = 25;

  static const double loadingIndicatorSize = 22;

  static const double loadingIndicatorStrokeWidth = 2.5;

  static const EdgeInsets continueButtonPadding =
      EdgeInsets.symmetric(
        horizontal: 20,
      );

  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(17),
  );

  static const LinearGradient primaryGradient =
      LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Color(0xFF1268F3),
          Color(0xFF0057EE),
        ],
      );

  static const List<BoxShadow> buttonShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x401268F3),
      blurRadius: 18,
      offset: Offset(0, 9),
    ),
  ];

  static const BoxDecoration continueButtonDecoration =
      BoxDecoration(
        gradient: primaryGradient,
        borderRadius: buttonRadius,
        boxShadow: buttonShadow,
      );

  // ==========================================================
  // BACKGROUND DECORATIONS
  // ==========================================================

  static const double decorativeCircleSize = 310;
  static const double decorativeDotSize = 8;
  static const double decorativeDotSpacing = 10;
  static const double bottomIllustrationSize = 88;

  static const int decorativeDotCount = 6;

  static const double topCircleTop = -170;
  static const double topCircleRight = -145;

  static const double topDotsTop = 145;
  static const double topDotsLeft = 28;

  static const double rightDotsTop = 175;
  static const double rightDotsRight = 24;

  // ==========================================================
  // TYPOGRAPHY
  // ==========================================================

  static const TextStyle titleStyle = TextStyle(
    fontSize: 34,
    height: 1.1,
    fontWeight: FontWeight.w800,
    color: titleColor,
    letterSpacing: -0.7,
  );

  static const TextStyle descriptionStyle = TextStyle(
    fontSize: 16,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: bodyColor,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    fontSize: 18,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: titleColor,
  );

  static const TextStyle sectionDescriptionStyle =
      TextStyle(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: bodyColor,
      );

  static const TextStyle offlineTitleStyle = TextStyle(
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: primaryDarkColor,
  );

  static const TextStyle offlineDescriptionStyle =
      TextStyle(
        fontSize: 13,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: bodyColor,
      );

  static const TextStyle inputStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: titleColor,
  );

  static const TextStyle inputHintStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: mutedColor,
  );

  static const TextStyle helperStyle = TextStyle(
    fontSize: 13,
    height: 1.4,
    color: bodyColor,
  );

  static const TextStyle roleTitleStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: titleColor,
  );

  static const TextStyle roleDescriptionStyle =
      TextStyle(
        fontSize: 8.5,
        height: 1.25,
        fontWeight: FontWeight.w400,
        color: bodyColor,
      );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: whiteColor,
  );

  // ==========================================================
  // INPUT DECORATION
  // ==========================================================

  static InputDecoration get nicknameInputDecoration {
    return const InputDecoration(
      hintText: nicknameHint,
      hintStyle: inputHintStyle,
      prefixIcon: Icon(
        Icons.person_outline_rounded,
        size: inputIconSize,
        color: primaryColor,
      ),
      counterText: '',
      contentPadding: inputContentPadding,
      filled: true,
      fillColor: surfaceColor,
      enabledBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(
          color: outlineColor,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(
          color: outlineColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(
          color: primaryColor,
          width: 1.7,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(
          color: Colors.redAccent,
          width: 1.7,
        ),
      ),
    );
  }
}