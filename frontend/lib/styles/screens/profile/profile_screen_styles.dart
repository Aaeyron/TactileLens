import 'package:flutter/material.dart';

abstract final class ProfileStyles {
  // Text
  static const String logoAsset = 'assets/icons/tactilelens_app_icon.png';

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

  // Colors
  static const Color backgroundColor = Color(0xFFF3F4F6);
  static const Color surfaceColor = Colors.white;

  static const Color primaryColor = Color(0xFF0D47A1);

  static const Color primaryBrightColor = Color(0xFF1268F3);

  static const Color titleColor = Color(0xFF07143D);

  static const Color bodyColor = Color(0xFF53658F);

  static const Color mutedColor = Color(0xFF8291B1);

  static const Color outlineColor = Color(0xFFBCD0EA);

  static const Color dividerColor = Color(0xFFDCE6F3);

  static const Color profileAvatarBackgroundColor = Color(0xFFEAF2FF);

  static const Color profileAvatarIconColor = Color(0xFF4C8DF6);

  static const Color roleBadgeBackgroundColor = Color(0xFFEDF4FF);

  static const Color menuIconBackgroundColor = Color(0xFFEDF4FF);

  static const Color logoutColor = Color(0xFFF04438);

  static const Color logoutIconBackgroundColor = Color(0xFFFFEEEE);

  // Icons
  static const IconData profileHeaderIcon = Icons.person_outline_rounded;

  static const IconData profileAvatarIcon = Icons.person_rounded;

  static const IconData editIcon = Icons.edit_outlined;

  static const IconData roleIcon = Icons.school_outlined;

  static const IconData accountInformationIcon = Icons.person_outline_rounded;

  static const IconData aboutTactileLensIcon = Icons.info_outline_rounded;

  static const IconData termsIcon = Icons.description_outlined;

  static const IconData settingsIcon = Icons.settings_outlined;

  static const IconData privacyIcon = Icons.shield_outlined;

  static const IconData logoutIcon = Icons.logout_rounded;

  static const IconData menuArrowIcon = Icons.chevron_right_rounded;

  // Screen layout
  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(16, 24, 16, 30);

  static const double profileTopSpacing = 42;
  static const double menuTopSpacing = 20;
  static const double menuGroupSpacing = 14;
  static const double bottomSpacing = 30;

  // Header
  static const double logoSize = 52;
  static const double logoTextSpacing = 14;

  static const BorderRadius logoRadius = BorderRadius.all(Radius.circular(14));

  static const double headerIconContainerSize = 44;
  static const double headerIconSize = 23;

  // Profile identity
  static const double profileLoadingHeight = 220;

  static const EdgeInsets profileContainerPadding = EdgeInsets.fromLTRB(
    20,
    28,
    20,
    26,
  );

  static const BorderRadius profileContainerRadius = BorderRadius.all(
    Radius.circular(18),
  );

  static const double profileAvatarSize = 176;
  static const double profileAvatarIconSize = 108;

  static const double profileNameSpacing = 24;
  static const double profileEmailSpacing = 7;
  static const double profileRoleSpacing = 16;

  static const double editButtonSize = 52;
  static const double editButtonRight = -2;
  static const double editButtonBottom = 4;
  static const double editButtonElevation = 5;
  static const double editIconSize = 23;

  static const Border avatarBorder = Border.fromBorderSide(
    BorderSide(color: Colors.white, width: 8),
  );

  static const List<BoxShadow> avatarShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x1F0D47A1),
      blurRadius: 24,
      spreadRadius: 2,
      offset: Offset(0, 8),
    ),
  ];

  // Role badge
  static const EdgeInsets roleBadgePadding = EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 10,
  );

  static const BorderRadius roleBadgeRadius = BorderRadius.all(
    Radius.circular(24),
  );

  static const Border roleBadgeBorder = Border.fromBorderSide(
    BorderSide(color: Color(0xFFD5E5FF)),
  );

  static const double roleIconSize = 21;
  static const double roleIconSpacing = 9;

  // Shared containers
  static const double cardBorderWidth = 1.1;

  static const Border cardBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor, width: cardBorderWidth),
  );

  static const Border smallContainerBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor),
  );

  static const List<BoxShadow> cardShadow = <BoxShadow>[];

  static const List<BoxShadow> smallContainerShadow = <BoxShadow>[
    BoxShadow(color: Color(0x100D47A1), blurRadius: 10, offset: Offset(0, 3)),
  ];

  // Menu
  static const BorderRadius menuRadius = BorderRadius.all(Radius.circular(20));

  static const EdgeInsets menuItemPadding = EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 16,
  );

  static const double menuIconContainerSize = 52;
  static const double menuIconSize = 27;
  static const double menuContentSpacing = 16;
  static const double menuArrowSize = 28;

  static const double dividerHeight = 1;
  static const double dividerIndent = 76;
  static const double dividerEndIndent = 18;

  // Snackbar
  static const Duration snackBarDuration = Duration(seconds: 2);

  static const EdgeInsets snackBarMargin = EdgeInsets.all(16);

  static const BorderRadius snackBarRadius = BorderRadius.all(
    Radius.circular(14),
  );

  // Text styles
  static const TextStyle appNameStyle = TextStyle(
    color: titleColor,
    fontSize: 25,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
  );

  static const TextStyle profileNameStyle = TextStyle(
    color: titleColor,
    fontSize: 29,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const TextStyle profileEmailStyle = TextStyle(
    color: bodyColor,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle roleBadgeTextStyle = TextStyle(
    color: primaryBrightColor,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle menuTitleStyle = TextStyle(
    color: titleColor,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle logoutTitleStyle = TextStyle(
    color: logoutColor,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle snackBarTextStyle = TextStyle(
    color: surfaceColor,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );
}
