import 'package:flutter/material.dart';

abstract final class ProfileStyles {
  // ============================================================
  // CONTENT
  // ============================================================

  static const String appName = 'TactileLens';

  static const String defaultUserName = 'TactileLens User';
  static const String defaultGuestName = 'Guest';

  static const String defaultRole = 'Learner';
  static const String defaultGuestRole = 'Learner';

  static const String guestModeLabel = 'Offline';
  static const String guestRoleSeparator = ' · ';

  static const String accountInformationTitle = 'Account Information';

  static const String aboutTactileLensTitle = 'About TactileLens';

  static const String termsTitle = 'Terms & Policy';
  static const String settingsTitle = 'Settings';
  static const String privacyTitle = 'Privacy & Security';
  static const String logoutTitle = 'Logout';

  static const String settingsUnavailableMessage =
      'Additional settings will be available soon.';

  static const String editProfileSemanticLabel = 'Open account information';

  // ============================================================
  // COLORS
  // ============================================================

  static const Color backgroundColor = Color(0xFFF4F7FC);
  static const Color surfaceColor = Colors.white;

  static const Color primaryColor = Color(0xFF1268F3);
  static const Color primaryDarkColor = Color(0xFF0758DD);
  static const Color primaryBrightColor = primaryColor;

  static const Color titleColor = Color(0xFF10213D);
  static const Color bodyColor = Color(0xFF42526B);
  static const Color textMutedColor = Color(0xFF728096);
  static const Color mutedColor = textMutedColor;

  static const Color outlineColor = Color(0xFFDDE5F0);
  static const Color dividerColor = Color(0xFFE7ECF3);

  static const Color profileAvatarBackgroundColor = Color(0xFFEDF4FF);

  static const Color profileAvatarIconColor = Color(0xFF1268F3);

  static const Color roleBadgeBackgroundColor = Color(0xFFEDF4FF);

  static const Color menuIconBackgroundColor = Color(0xFFF4F7FC);

  static const Color logoutColor = Color(0xFFF04438);

  static const Color logoutIconBackgroundColor = Color(0xFFFFEEEE);

  // ============================================================
  // ICONS
  // ============================================================

  static const IconData profileAvatarIcon = Icons.person_rounded;

  static const IconData accountInformationIcon = Icons.person_outline_rounded;

  static const IconData aboutTactileLensIcon = Icons.info_outline_rounded;

  static const IconData termsIcon = Icons.description_outlined;

  static const IconData settingsIcon = Icons.settings_outlined;

  static const IconData privacyIcon = Icons.shield_outlined;

  static const IconData logoutIcon = Icons.logout_rounded;

  static const IconData menuArrowIcon = Icons.chevron_right_rounded;

  // Compatibility icons retained for related profile screens.
  static const IconData profileHeaderIcon = Icons.person_outline_rounded;

  static const IconData editIcon = Icons.edit_outlined;
  static const IconData roleIcon = Icons.school_outlined;

  // ============================================================
  // FULL-WIDTH HEADER
  // ============================================================

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1474F5), Color(0xFF0758DD)],
  );

  static const double headerHorizontalPadding = 16;
  static const double headerTopPadding = 18;
  static const double headerBottomPadding = 22;

  static const double headerContentHeight = 158;

  static const BorderRadius headerRadius = BorderRadius.only(
    bottomLeft: Radius.elliptical(180, 48),
    bottomRight: Radius.elliptical(180, 48),
  );

  static const double headerAvatarSize = 91;
  static const double headerAvatarIconSize = 59;
  static const double headerAvatarSpacing = 14;
  static const double headerAvatarBottom = 10;
  static const double headerIdentityBottom = 18;

  static const Border avatarBorder = Border.fromBorderSide(
    BorderSide(color: Colors.white, width: 4),
  );

  static const List<BoxShadow> avatarShadow = <BoxShadow>[
    BoxShadow(color: Color(0x24102A43), blurRadius: 18, offset: Offset(0, 7)),
  ];

  // ============================================================
  // SCREEN CONTENT
  // ============================================================

  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(12, 22, 12, 30);

  // Compatibility with any remaining references.
  static const EdgeInsets screenPadding = contentPadding;

  static const double menuItemSpacing = 10;
  static const double menuSectionSpacing = 18;
  static const double logoutTopSpacing = 28;
  static const double bottomSpacing = 30;

  static const double profileLoadingHeight = 128;

  // ============================================================
  // MENU CARDS
  // ============================================================

  static const BorderRadius menuRadius = BorderRadius.all(Radius.circular(13));

  static const EdgeInsets menuItemPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 13,
  );

  static const double menuIconContainerSize = 43;
  static const double menuIconSize = 23;
  static const double menuContentSpacing = 13;
  static const double menuDescriptionSpacing = 4;
  static const double menuArrowSpacing = 8;
  static const double menuArrowSize = 22;

  static const Border cardBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor, width: 1),
  );

  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x0D102A43), blurRadius: 11, offset: Offset(0, 4)),
  ];

  // Compatibility values.
  static const Border smallContainerBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor),
  );

  static const double cardBorderWidth = 1;
  static const double dividerHeight = 1;
  static const double dividerIndent = 70;
  static const double dividerEndIndent = 16;

  // ============================================================
  // LEGACY PROFILE VALUES
  // ============================================================

  static const EdgeInsets profileContainerPadding = EdgeInsets.all(20);

  static const BorderRadius profileContainerRadius = BorderRadius.all(
    Radius.circular(18),
  );

  static const double profileAvatarSize = 91;
  static const double profileAvatarIconSize = 59;

  static const double profileTopSpacing = 0;
  static const double menuTopSpacing = 20;
  static const double menuGroupSpacing = 14;

  static const double profileNameSpacing = 12;
  static const double profileEmailSpacing = 6;
  static const double profileRoleSpacing = 5;

  static const double editButtonSize = 42;
  static const double editButtonRight = 0;
  static const double editButtonBottom = 0;
  static const double editButtonElevation = 0;
  static const double editIconSize = 21;

  static const EdgeInsets roleBadgePadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 8,
  );

  static const BorderRadius roleBadgeRadius = BorderRadius.all(
    Radius.circular(22),
  );

  static const Border roleBadgeBorder = Border.fromBorderSide(
    BorderSide(color: Color(0xFFD5E5FF)),
  );

  static const double roleIconSize = 19;
  static const double roleIconSpacing = 8;

  static const List<BoxShadow> smallContainerShadow = <BoxShadow>[];

  // ============================================================
  // DIALOGS AND SNACKBAR
  // ============================================================

  static const BorderRadius dialogRadius = BorderRadius.all(
    Radius.circular(18),
  );

  static const Duration snackBarDuration = Duration(seconds: 2);

  static const EdgeInsets snackBarMargin = EdgeInsets.all(16);

  static const BorderRadius snackBarRadius = BorderRadius.all(
    Radius.circular(14),
  );

  // ============================================================
  // TYPOGRAPHY
  // ============================================================

  static const TextStyle appNameStyle = TextStyle(
    color: surfaceColor,
    fontSize: 18,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static const TextStyle profileNameStyle = TextStyle(
    color: surfaceColor,
    fontSize: 21,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static const TextStyle profileRoleStyle = TextStyle(
    color: Color(0xFFE9F2FF),
    fontSize: 13,
    height: 1.2,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle profileEmailStyle = TextStyle(
    color: Color(0xFFE9F2FF),
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle roleBadgeTextStyle = TextStyle(
    color: primaryColor,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle menuTitleStyle = TextStyle(
    color: titleColor,
    fontSize: 13.5,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle menuDescriptionStyle = TextStyle(
    color: bodyColor,
    fontSize: 10.5,
    height: 1.3,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle logoutTitleStyle = TextStyle(
    color: logoutColor,
    fontSize: 13.5,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle logoutDescriptionStyle = TextStyle(
    color: logoutColor,
    fontSize: 10.5,
    height: 1.3,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle dialogTitleStyle = TextStyle(
    color: titleColor,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle dialogDescriptionStyle = TextStyle(
    color: bodyColor,
    fontSize: 13,
    height: 1.5,
  );

  static const TextStyle snackBarTextStyle = TextStyle(
    color: surfaceColor,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );
}
