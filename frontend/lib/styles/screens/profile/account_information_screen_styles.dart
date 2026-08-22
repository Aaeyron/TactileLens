import 'package:flutter/material.dart';

abstract final class AccountInformationStyles {
  // Text
  static const String screenTitle =
      'Account Information';

  static const String screenDescription =
      'View your personal and account information.';

  static const String backTooltip =
      'Return to Profile';

  static const String defaultUserName =
      'TactileLens User';

  static const String defaultGuestName = 'Guest';
  static const String defaultRole = 'Learner';
  static const String defaultInitial = 'T';

  static const String guestEmailDescription =
      'Offline guest account';

  static const String unavailableValue =
      'Not available';

  static const String personalDetailsTitle =
      'Personal Details';

  static const String additionalInformationTitle =
      'Additional Information';

  static const String fullNameTitle = 'Full Name';
  static const String nicknameTitle = 'Nickname';
  static const String emailTitle = 'Email Address';
  static const String passwordTitle = 'Password';
  static const String roleTitle = 'Role';

  static const String accountTypeTitle =
      'Account Type';

  static const String storageTitle = 'Storage Mode';
  static const String languageTitle = 'Language';

  static const String guestAccountType =
      'Offline Guest';

  static const String registeredAccountType =
      'Signed-in Account';

  static const String localStorageMode =
      'Stored on this device';

  static const String hybridStorageMode =
      'Online and offline';

  static const String defaultLanguage =
      'English';

  static const String maskedPassword = '••••••••';

  static const String editButtonTitle = 'Edit';
  static const String changeLabel = 'Change';

  static const String editUnavailableMessage =
      'Editing personal details will be available soon.';

  static const String passwordUnavailableMessage =
      'Password changes will be available soon.';

  static const String roleUnavailableMessage =
      'Role changes will be available soon.';

  static const String languageUnavailableMessage =
      'Language selection will be available soon.';

  static const String securityTitle =
      'Keep your account secure';

  static const String securityDescription =
      'Review your privacy and security options to keep your data safe.';

  // Colors
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Colors.white;

  static const Color primaryColor =
      Color(0xFF0D47A1);

  static const Color primaryBrightColor =
      Color(0xFF1268F3);

  static const Color titleColor =
      Color(0xFF07143D);

  static const Color bodyColor =
      Color(0xFF53658F);

  static const Color mutedColor =
      Color(0xFF8291B1);

  static const Color outlineColor =
      Color(0xFFBCD0EA);

  static const Color dividerColor =
      Color(0xFFDCE6F3);

  static const Color avatarBackgroundColor =
      Color(0xFFEAF2FF);

  static const Color roleBadgeBackgroundColor =
      Color(0xFFEDF4FF);

  static const Color informationIconBackgroundColor =
      Color(0xFFEDF4FF);

  static const Color securityBackgroundColor =
      Color(0xFFF6FAFF);

  // Icons
  static const IconData backIcon =
      Icons.arrow_back_rounded;

  static const IconData editIcon =
      Icons.edit_outlined;

  static const IconData roleIcon =
      Icons.school_outlined;

  static const IconData emailIcon =
      Icons.email_outlined;

  static const IconData personalDetailsIcon =
      Icons.person_outline_rounded;

  static const IconData fullNameIcon =
      Icons.badge_outlined;

  static const IconData nicknameIcon =
      Icons.person_outline_rounded;

  static const IconData passwordIcon =
      Icons.lock_outline_rounded;

  static const IconData roleValueIcon =
      Icons.person_outline_rounded;

  static const IconData additionalInformationIcon =
      Icons.info_outline_rounded;

  static const IconData accountTypeIcon =
      Icons.account_circle_outlined;

  static const IconData storageIcon =
      Icons.storage_outlined;

  static const IconData languageIcon =
      Icons.language_rounded;

  static const IconData securityIcon =
      Icons.shield_rounded;

  static const IconData forwardIcon =
      Icons.chevron_right_rounded;

  // Screen layout
  static const EdgeInsets screenPadding =
      EdgeInsets.fromLTRB(20, 20, 20, 28);

  static const double headerBottomSpacing = 28;
  static const double sectionSpacing = 20;
  static const double bottomSpacing = 30;
  static const double loadingHeight = 420;

  // Header
  static const EdgeInsets headerTitlePadding =
      EdgeInsets.symmetric(horizontal: 54);

  static const double backIconSize = 27;

  static const double headerDescriptionSpacing = 7;

  // Shared cards
  static const BorderRadius cardRadius =
      BorderRadius.all(Radius.circular(20));

  static const double cardBorderWidth = 1.1;

  static const Border cardBorder =
      Border.fromBorderSide(
    BorderSide(
      color: outlineColor,
      width: cardBorderWidth,
    ),
  );

  static const List<BoxShadow> cardShadow =
      <BoxShadow>[
    BoxShadow(
      color: Color(0x180D47A1),
      blurRadius: 18,
      spreadRadius: 1,
      offset: Offset(0, 6),
    ),
  ];

  // Profile summary
  static const EdgeInsets profileCardPadding =
      EdgeInsets.all(22);

  static const double profileAvatarSize = 112;
  static const double profileContentSpacing = 22;
  static const double profileRoleSpacing = 11;
  static const double profileEmailSpacing = 15;

  static const Border avatarBorder =
      Border.fromBorderSide(
    BorderSide(
      color: Color(0xFFD8E7FF),
      width: 1.5,
    ),
  );

  static const double editAvatarSize = 46;
  static const double editAvatarRight = -7;
  static const double editAvatarBottom = -4;
  static const double editAvatarElevation = 4;
  static const double editAvatarIconSize = 21;

  static const EdgeInsets roleBadgePadding =
      EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 8,
  );

  static const BorderRadius roleBadgeRadius =
      BorderRadius.all(Radius.circular(20));

  static const double roleIconSize = 19;
  static const double roleIconSpacing = 7;

  static const double profileEmailIconSize = 20;
  static const double profileEmailIconSpacing = 9;

  // Information sections
  static const EdgeInsets sectionHeaderPadding =
      EdgeInsets.fromLTRB(20, 20, 20, 12);

  static const double sectionHeaderIconSize = 25;
  static const double sectionHeaderIconSpacing = 12;

  static const EdgeInsets informationTilePadding =
      EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 16,
  );

  static const double informationIconContainerSize = 48;

  static const BorderRadius informationIconRadius =
      BorderRadius.all(Radius.circular(13));

  static const double informationIconSize = 23;
  static const double informationContentSpacing = 14;
  static const double informationValueSpacing = 5;
  static const double informationActionSpacing = 8;

  static const double dividerHeight = 1;
  static const double dividerIndent = 82;
  static const double dividerEndIndent = 20;

  // Actions
  static const double actionButtonIconSize = 19;

  static final ButtonStyle backButtonStyle =
      IconButton.styleFrom(
    foregroundColor: titleColor,
    backgroundColor: surfaceColor,
    shape: const CircleBorder(),
  );

  static final ButtonStyle sectionActionButtonStyle =
      TextButton.styleFrom(
    foregroundColor: primaryBrightColor,
    backgroundColor: roleBadgeBackgroundColor,
    padding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 9,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.all(Radius.circular(18)),
    ),
  );

  static final ButtonStyle informationActionButtonStyle =
      TextButton.styleFrom(
    foregroundColor: primaryBrightColor,
    backgroundColor: roleBadgeBackgroundColor,
    padding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 8,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.all(Radius.circular(18)),
    ),
  );

  // Security banner
  static const EdgeInsets securityPadding =
      EdgeInsets.all(20);

  static const Border securityBorder =
      Border.fromBorderSide(
    BorderSide(
      color: Color(0xFFD4E4FF),
      width: 1.1,
    ),
  );

  static const List<BoxShadow> securityShadow =
      <BoxShadow>[
    BoxShadow(
      color: Color(0x100D47A1),
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
  ];

  static const double securityIconSize = 42;
  static const double securityContentSpacing = 15;
  static const double securityDescriptionSpacing = 5;
  static const double forwardIconSize = 25;

  // Snackbar
  static const Duration snackBarDuration =
      Duration(seconds: 2);

  static const EdgeInsets snackBarMargin =
      EdgeInsets.all(16);

  static const BorderRadius snackBarRadius =
      BorderRadius.all(Radius.circular(14));

  // Text styles
  static const TextStyle screenTitleStyle =
      TextStyle(
    color: titleColor,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.25,
  );

  static const TextStyle headerDescriptionStyle =
      TextStyle(
    color: bodyColor,
    fontSize: 14,
    height: 1.4,
  );

  static const TextStyle avatarTextStyle =
      TextStyle(
    color: primaryBrightColor,
    fontSize: 48,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle profileNameStyle =
      TextStyle(
    color: titleColor,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
  );

  static const TextStyle profileEmailStyle =
      TextStyle(
    color: bodyColor,
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle roleBadgeTextStyle =
      TextStyle(
    color: primaryBrightColor,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle sectionTitleStyle =
      TextStyle(
    color: titleColor,
    fontSize: 17,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle informationTitleStyle =
      TextStyle(
    color: titleColor,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle informationValueStyle =
      TextStyle(
    color: bodyColor,
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle securityTitleStyle =
      TextStyle(
    color: primaryBrightColor,
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle securityDescriptionStyle =
      TextStyle(
    color: bodyColor,
    fontSize: 13,
    height: 1.4,
  );

  static const TextStyle snackBarTextStyle =
      TextStyle(
    color: surfaceColor,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );
}