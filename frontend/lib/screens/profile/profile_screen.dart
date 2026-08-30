import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../styles/screens/profile/profile_screen_styles.dart';
import '../../utils/session_manager.dart';
import '../../widgets/profile/logout_dialog.dart';
import '../auth/auth_screen.dart';
import 'about_tactilelens_screen.dart';
import 'account_information_screen.dart';
import 'privacy_security_screen.dart';
import 'terms_policy_screen.dart';

abstract final class _ProfileText {
  static const String exitGuestModeTitle = 'Exit Guest Mode';
  static const String exitGuestModeDescription = 'Return to the sign-in screen';

  static const String logoutDescription = 'Sign out of your account';

  static const String exitGuestDialogTitle = 'Exit Guest Mode?';

  static const String exitGuestDialogDescription =
      'You will return to the sign-in screen. Your locally saved scans, '
      'history, materials, and folders will remain on this device.';

  static const String cancelLabel = 'Cancel';
  static const String exitLabel = 'Exit';

  static const String accountInformationDescription =
      'Manage your personal details';

  static const String aboutDescription =
      'App information and accessibility mission';

  static const String termsDescription = 'Review the app terms and policies';

  static const String settingsDescription = 'Customize your app experience';

  static const String privacyDescription =
      'Manage privacy and security preferences';
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _entranceOpacity;
  late final Animation<Offset> _entrancePosition;

  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _role = '';
  String _guestNickname = '';

  bool _isGuest = false;
  bool _isLoadingProfile = true;
  bool _isEndingSession = false;

  @override
  void initState() {
    super.initState();

    _initializeEntranceAnimation();
    _loadUser();
  }

  void _initializeEntranceAnimation() {
    _entranceController = AnimationController(
      vsync: this,
      duration: ProfileStyles.entranceAnimationDuration,
    );

    final CurvedAnimation entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: ProfileStyles.entranceAnimationCurve,
    );

    _entranceOpacity = Tween<double>(
      begin: ProfileStyles.entranceFadeBegin,
      end: ProfileStyles.entranceFadeEnd,
    ).animate(entranceAnimation);

    _entrancePosition = Tween<Offset>(
      begin: ProfileStyles.entranceSlideBegin,
      end: Offset.zero,
    ).animate(entranceAnimation);

    Future<void>.delayed(ProfileStyles.entranceAnimationDelay, () {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final bool isGuest = await SessionManager.isGuest();

    if (isGuest) {
      final String guestNickname =
          await SessionManager.getGuestNickname() ?? '';

      final String role = await SessionManager.getRole() ?? '';

      if (!mounted) {
        return;
      }

      setState(() {
        _isGuest = true;
        _guestNickname = guestNickname.trim();
        _role = role.trim();
        _isLoadingProfile = false;
      });

      return;
    }

    final String firstName = await SessionManager.getFirstName() ?? '';

    final String lastName = await SessionManager.getLastName() ?? '';

    final String email = await SessionManager.getEmail() ?? '';

    final String role = await SessionManager.getRole() ?? '';

    if (!mounted) {
      return;
    }

    setState(() {
      _isGuest = false;
      _firstName = firstName.trim();
      _lastName = lastName.trim();
      _email = email.trim();
      _role = role.trim();
      _isLoadingProfile = false;
    });
  }

  String get _displayName {
    if (_isGuest) {
      return _guestNickname.isEmpty
          ? ProfileStyles.defaultGuestName
          : _guestNickname;
    }

    final String fullName = <String>[
      _firstName,
      _lastName,
    ].where((String value) => value.isNotEmpty).join(' ');

    return fullName.isEmpty ? ProfileStyles.defaultUserName : fullName;
  }

  String get _displayRole {
    final String normalizedRole = _role.trim();

    if (normalizedRole.isEmpty) {
      return _isGuest
          ? ProfileStyles.defaultGuestRole
          : ProfileStyles.defaultRole;
    }

    final String formattedRole =
        '${normalizedRole[0].toUpperCase()}'
        '${normalizedRole.substring(1).toLowerCase()}';

    if (_isGuest) {
      return '$formattedRole'
          '${ProfileStyles.guestRoleSeparator}'
          '${ProfileStyles.guestModeLabel}';
    }

    return formattedRole;
  }

  void _openAccountInformation() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const AccountInformationScreen();
        },
      ),
    );
  }

  void _openAboutTactileLens() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const AboutTactileLensScreen();
        },
      ),
    );
  }

  void _openTermsPolicy() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const TermsPolicyScreen();
        },
      ),
    );
  }

  void _openPrivacySecurity() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const PrivacySecurityScreen();
        },
      ),
    );
  }

  void _openSettings() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: ProfileStyles.snackBarDuration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: ProfileStyles.primaryColor,
          margin: ProfileStyles.snackBarMargin,
          shape: const RoundedRectangleBorder(
            borderRadius: ProfileStyles.snackBarRadius,
          ),
          content: const Text(
            ProfileStyles.settingsUnavailableMessage,
            style: ProfileStyles.snackBarTextStyle,
          ),
        ),
      );
  }

  Future<void> _requestSessionExit() async {
    if (_isEndingSession) {
      return;
    }

    if (!_isGuest) {
      showLogoutDialog(context);
      return;
    }

    final bool shouldExit = await _showExitGuestConfirmation();

    if (!mounted || !shouldExit) {
      return;
    }

    setState(() {
      _isEndingSession = true;
    });

    try {
      await SessionManager.logout();

      if (!mounted) {
        return;
      }

      await Navigator.of(context).pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return const AuthScreen();
          },
        ),
        (Route<dynamic> route) => false,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isEndingSession = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: ProfileStyles.primaryColor,
            content: Text(
              'Unable to exit guest mode. Please try again.',
              style: ProfileStyles.snackBarTextStyle,
            ),
          ),
        );
    }
  }

  Future<bool> _showExitGuestConfirmation() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: !_isEndingSession,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: ProfileStyles.surfaceColor,
          shape: const RoundedRectangleBorder(
            borderRadius: ProfileStyles.dialogRadius,
            side: BorderSide(color: ProfileStyles.outlineColor),
          ),
          title: const Text(
            _ProfileText.exitGuestDialogTitle,
            style: ProfileStyles.dialogTitleStyle,
          ),
          content: const Text(
            _ProfileText.exitGuestDialogDescription,
            style: ProfileStyles.dialogDescriptionStyle,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(_ProfileText.cancelLabel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ProfileStyles.logoutColor,
                foregroundColor: ProfileStyles.surfaceColor,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(_ProfileText.exitLabel),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: ProfileStyles.backgroundColor,
        body: FadeTransition(
          opacity: _entranceOpacity,
          child: SlideTransition(
            position: _entrancePosition,
            child: RefreshIndicator(
              color: ProfileStyles.primaryColor,
              backgroundColor: ProfileStyles.surfaceColor,
              onRefresh: _loadUser,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: <Widget>[
                  SliverToBoxAdapter(child: _buildProfileHeader(context)),
                  SliverPadding(
                    padding: ProfileStyles.contentPadding,
                    sliver: SliverList(
                      delegate: SliverChildListDelegate.fixed(<Widget>[
                        _ProfileMenuItem(
                          icon: ProfileStyles.accountInformationIcon,
                          title: ProfileStyles.accountInformationTitle,
                          description:
                              _ProfileText.accountInformationDescription,
                          onPressed: _openAccountInformation,
                        ),
                        const SizedBox(height: ProfileStyles.menuItemSpacing),
                        _ProfileMenuItem(
                          icon: ProfileStyles.aboutTactileLensIcon,
                          title: ProfileStyles.aboutTactileLensTitle,
                          description: _ProfileText.aboutDescription,
                          onPressed: _openAboutTactileLens,
                        ),
                        const SizedBox(height: ProfileStyles.menuItemSpacing),
                        _ProfileMenuItem(
                          icon: ProfileStyles.termsIcon,
                          title: ProfileStyles.termsTitle,
                          description: _ProfileText.termsDescription,
                          onPressed: _openTermsPolicy,
                        ),
                        const SizedBox(
                          height: ProfileStyles.menuSectionSpacing,
                        ),
                        _ProfileMenuItem(
                          icon: ProfileStyles.settingsIcon,
                          title: ProfileStyles.settingsTitle,
                          description: _ProfileText.settingsDescription,
                          onPressed: _openSettings,
                        ),
                        const SizedBox(height: ProfileStyles.menuItemSpacing),
                        _ProfileMenuItem(
                          icon: ProfileStyles.privacyIcon,
                          title: ProfileStyles.privacyTitle,
                          description: _ProfileText.privacyDescription,
                          onPressed: _openPrivacySecurity,
                        ),
                        const SizedBox(height: ProfileStyles.logoutTopSpacing),
                        _ProfileMenuItem(
                          icon: ProfileStyles.logoutIcon,
                          title: _isGuest
                              ? _ProfileText.exitGuestModeTitle
                              : ProfileStyles.logoutTitle,
                          description: _isGuest
                              ? _ProfileText.exitGuestModeDescription
                              : _ProfileText.logoutDescription,
                          iconColor: ProfileStyles.logoutColor,
                          titleStyle: ProfileStyles.logoutTitleStyle,
                          descriptionStyle:
                              ProfileStyles.logoutDescriptionStyle,
                          arrowColor: ProfileStyles.logoutColor,
                          iconBackgroundColor:
                              ProfileStyles.logoutIconBackgroundColor,
                          onPressed: _requestSessionExit,
                        ),
                        const SizedBox(height: ProfileStyles.bottomSpacing),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final double statusBarHeight = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        ProfileStyles.headerHorizontalPadding,
        statusBarHeight + ProfileStyles.headerTopPadding,
        ProfileStyles.headerHorizontalPadding,
        ProfileStyles.headerBottomPadding,
      ),
      decoration: const BoxDecoration(
        gradient: ProfileStyles.headerGradient,
        borderRadius: ProfileStyles.headerRadius,
      ),
      child: _isLoadingProfile
          ? const SizedBox(
              height: ProfileStyles.headerContentHeight,
              child: Center(
                child: CircularProgressIndicator(
                  color: ProfileStyles.surfaceColor,
                ),
              ),
            )
          : SizedBox(
              height: ProfileStyles.headerContentHeight,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: Text(
                      ProfileStyles.appName,
                      style: ProfileStyles.appNameStyle,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right:
                        ProfileStyles.headerAvatarSize +
                        ProfileStyles.headerAvatarSpacing,
                    bottom: ProfileStyles.headerIdentityBottom,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: ProfileStyles.profileNameStyle,
                        ),
                        const SizedBox(
                          height: ProfileStyles.profileRoleSpacing,
                        ),
                        Text(
                          _displayRole,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ProfileStyles.profileRoleStyle,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: ProfileStyles.headerAvatarBottom,
                    child: Semantics(
                      button: true,
                      label: ProfileStyles.editProfileSemanticLabel,
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _openAccountInformation,
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: ProfileStyles.headerAvatarSize,
                            height: ProfileStyles.headerAvatarSize,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: ProfileStyles.profileAvatarBackgroundColor,
                              shape: BoxShape.circle,
                              border: ProfileStyles.avatarBorder,
                              boxShadow: ProfileStyles.avatarShadow,
                            ),
                            child: const Icon(
                              ProfileStyles.profileAvatarIcon,
                              size: ProfileStyles.headerAvatarIconSize,
                              color: ProfileStyles.profileAvatarIconColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.onPressed,
    this.iconColor = ProfileStyles.primaryColor,
    this.arrowColor = ProfileStyles.textMutedColor,
    this.iconBackgroundColor = ProfileStyles.menuIconBackgroundColor,
    this.titleStyle = ProfileStyles.menuTitleStyle,
    this.descriptionStyle = ProfileStyles.menuDescriptionStyle,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onPressed;

  final Color iconColor;
  final Color arrowColor;
  final Color iconBackgroundColor;

  final TextStyle titleStyle;
  final TextStyle descriptionStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ProfileStyles.surfaceColor,
        borderRadius: ProfileStyles.menuRadius,
        border: ProfileStyles.cardBorder,
        boxShadow: ProfileStyles.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: ProfileStyles.menuItemPadding,
            child: Row(
              children: <Widget>[
                Container(
                  width: ProfileStyles.menuIconContainerSize,
                  height: ProfileStyles.menuIconContainerSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: ProfileStyles.menuIconSize,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: ProfileStyles.menuContentSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: titleStyle),
                      const SizedBox(
                        height: ProfileStyles.menuDescriptionSpacing,
                      ),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: descriptionStyle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: ProfileStyles.menuArrowSpacing),
                Icon(
                  ProfileStyles.menuArrowIcon,
                  size: ProfileStyles.menuArrowSize,
                  color: arrowColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
