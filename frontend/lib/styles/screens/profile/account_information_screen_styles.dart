import 'package:flutter/material.dart';

abstract final class AccountInformationStyles {
  // ============================================================
  // CONTENT
  // ============================================================

  static const String screenTitle = 'Account Information';

  static const String screenDescription =
      'View your personal details and account preferences.';

  static const String backTooltip = 'Return to Profile';

  static const String defaultUserName = 'TactileLens User';
  static const String defaultGuestName = 'Guest';
  static const String defaultRole = 'Learner';
  static const String defaultInitial = 'T';

  static const String guestEmailDescription = 'Offline guest account';
  static const String unavailableValue = 'Not available';

  static const String personalDetailsTitle = 'Personal Details';
  static const String accountDetailsTitle = 'Account Details';

  static const String fullNameTitle = 'Full Name';
  static const String nicknameTitle = 'Nickname';
  static const String emailTitle = 'Email Address';
  static const String roleTitle = 'Role';

  static const String accountTypeTitle = 'Account Type';
  static const String storageTitle = 'Storage Mode';
  static const String languageTitle = 'Language';

  static const String guestAccountType = 'Offline Guest';
  static const String registeredAccountType = 'Signed-in Account';

  static const String localStorageMode = 'Stored on this device';
  static const String hybridStorageMode = 'Online and offline';

  static const String defaultLanguage = 'English';

  static const String guestNoticeTitle = 'You are using Guest Mode';

  static const String guestNoticeDescription =
      'Your scans, history, and materials are stored locally on this device.';

  static const String securityTitle = 'Privacy & Security';

  static const String securityDescription =
      'Review how your account and learning data are protected.';

  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryColor = Color(0xFF1268F3);
  static const Color primaryDarkColor = Color(0xFF0758DD);

  static const Color backgroundColor = Color(0xFFF4F7FC);
  static const Color surfaceColor = Colors.white;

  static const Color titleColor = Color(0xFF10213D);
  static const Color bodyColor = Color(0xFF42526B);
  static const Color mutedColor = Color(0xFF728096);

  static const Color outlineColor = Color(0xFFDDE5F0);
  static const Color dividerColor = Color(0xFFE5EBF3);

  static const Color roleBadgeBackgroundColor = Color(0xFFEAF2FF);
  static const Color informationIconBackgroundColor = Color(0xFFEDF4FF);

  static const Color securityBackgroundColor = Color(0xFFF6FAFF);
  static const Color noticeBackgroundColor = Color(0xFFFFFAEB);

  // ============================================================
  // ANIMATIONS
  // ============================================================

  static const Duration entranceDuration = Duration(milliseconds: 540);

  static const Duration entranceDelay = Duration(milliseconds: 100);

  static const Curve entranceCurve = Curves.easeOutCubic;

  static const Offset entranceBeginOffset = Offset(0, 0.025);

  // ============================================================
  // ICONS
  // ============================================================

  static const IconData backIcon = Icons.arrow_back_rounded;

  static const IconData roleIcon = Icons.school_outlined;

  static const IconData personalDetailsIcon = Icons.person_outline_rounded;

  static const IconData fullNameIcon = Icons.badge_outlined;
  static const IconData nicknameIcon = Icons.person_outline_rounded;
  static const IconData emailIcon = Icons.email_outlined;
  static const IconData roleValueIcon = Icons.school_outlined;

  static const IconData accountTypeIcon = Icons.account_circle_outlined;

  static const IconData storageIcon = Icons.storage_outlined;
  static const IconData languageIcon = Icons.language_rounded;

  static const IconData securityIcon = Icons.shield_outlined;
  static const IconData offlineIcon = Icons.cloud_off_outlined;

  static const IconData forwardIcon = Icons.chevron_right_rounded;

  // ============================================================
  // HEADER
  // ============================================================

  static const double headerHeight = 178;
  static const double headerTopPadding = 12;
  static const double headerBottomPadding = 24;
  static const double headerHorizontalPadding = 14;

  static const double headerBackSpacing = 5;
  static const double headerTextSpacing = 15;

  static const EdgeInsets headerDescriptionPadding = EdgeInsets.symmetric(
    horizontal: 5,
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1474F5), Color(0xFF0758DD)],
  );

  static const BorderRadius headerRadius = BorderRadius.only(
    bottomLeft: Radius.elliptical(190, 38),
    bottomRight: Radius.elliptical(190, 38),
  );

  static const double decorationRight = 18;
  static const double decorationTop = 65;
  static const double decorationOpacity = 0.18;
  static const double decorationWidth = 49;
  static const double decorationDotSize = 4;
  static const double decorationDotSpacing = 7;
  static const int decorationDotCount = 12;

  static const double backIconSize = 25;

  static final ButtonStyle backButtonStyle = IconButton.styleFrom(
    foregroundColor: surfaceColor,
    backgroundColor: const Color(0x26FFFFFF),
    shape: const CircleBorder(),
  );

  // ============================================================
  // AVATAR
  // ============================================================

  static const double avatarOuterSize = 108;
  static const double avatarOverlapSpace = 61;
  static const double avatarHorizontalInset = 20;
  static const double avatarBottom = 0;

  static const EdgeInsets avatarOuterPadding = EdgeInsets.all(5);

  static const LinearGradient avatarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF66A6FF), Color(0xFF1268F3)],
  );

  static const List<BoxShadow> avatarShadow = <BoxShadow>[
    BoxShadow(color: Color(0x3310213D), blurRadius: 20, offset: Offset(0, 7)),
  ];

  // ============================================================
  // LAYOUT
  // ============================================================

  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(14, 8, 14, 30);

  static const double sectionSpacing = 14;
  static const double bottomSpacing = 28;
  static const double loadingHeight = 380;

  // ============================================================
  // CARDS
  // ============================================================

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(15));

  static const Border cardBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor, width: 1),
  );

  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x0D102A43), blurRadius: 12, offset: Offset(0, 4)),
  ];

  // ============================================================
  // IDENTITY CARD
  // ============================================================

  static const EdgeInsets identityCardPadding = EdgeInsets.fromLTRB(
    18,
    20,
    18,
    20,
  );

  static const double profileRoleSpacing = 10;
  static const double profileEmailSpacing = 12;

  static const EdgeInsets roleBadgePadding = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 7,
  );

  static const BorderRadius roleBadgeRadius = BorderRadius.all(
    Radius.circular(18),
  );

  static const double roleIconSize = 17;
  static const double roleIconSpacing = 6;

  // ============================================================
  // INFORMATION SECTIONS
  // ============================================================

  static const EdgeInsets sectionHeaderPadding = EdgeInsets.fromLTRB(
    17,
    17,
    17,
    11,
  );

  static const double sectionHeaderIconSize = 22;
  static const double sectionHeaderIconSpacing = 10;

  static const EdgeInsets informationRowPadding = EdgeInsets.symmetric(
    horizontal: 17,
    vertical: 14,
  );

  static const double informationIconContainerSize = 42;

  static const BorderRadius informationIconRadius = BorderRadius.all(
    Radius.circular(11),
  );

  static const double informationIconSize = 21;
  static const double rowContentSpacing = 12;
  static const double rowActionSpacing = 8;
  static const double informationValueSpacing = 4;

  static const double dividerIndent = 71;
  static const double dividerEndIndent = 17;

  // ============================================================
  // NOTICE AND SECURITY
  // ============================================================

  static const EdgeInsets noticePadding = EdgeInsets.all(16);

  static const Border noticeBorder = Border.fromBorderSide(
    BorderSide(color: Color(0xFFF2D38A), width: 1),
  );

  static const double noticeDescriptionSpacing = 4;

  static const EdgeInsets securityPadding = EdgeInsets.all(16);

  static const Border securityBorder = Border.fromBorderSide(
    BorderSide(color: Color(0xFFCCE0FF), width: 1),
  );

  static const double securityDescriptionSpacing = 4;
  static const double forwardIconSize = 23;

  // ============================================================
  // TEXT STYLES
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

  static const TextStyle avatarTextStyle = TextStyle(
    color: surfaceColor,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
  );

  static const TextStyle profileNameStyle = TextStyle(
    color: titleColor,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
  );

  static const TextStyle profileEmailStyle = TextStyle(
    color: bodyColor,
    fontSize: 13.5,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle roleBadgeTextStyle = TextStyle(
    color: primaryColor,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    color: titleColor,
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle informationLabelStyle = TextStyle(
    color: mutedColor,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle informationValueStyle = TextStyle(
    color: titleColor,
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle noticeTitleStyle = TextStyle(
    color: Color(0xFF8A5A00),
    fontSize: 14,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle noticeDescriptionStyle = TextStyle(
    color: Color(0xFF7A5D23),
    fontSize: 12.5,
    height: 1.4,
  );

  static const TextStyle securityTitleStyle = TextStyle(
    color: primaryColor,
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle securityDescriptionStyle = TextStyle(
    color: bodyColor,
    fontSize: 12.5,
    height: 1.4,
  );
}
