import '../auth/auth_screen.dart';
import 'package:flutter/material.dart';

import '../../styles/screens/profile/profile_screen_styles.dart';
import '../../utils/session_manager.dart';
import '../../widgets/profile/logout_dialog.dart';
import 'about_tactilelens_screen.dart';
import 'account_information_screen.dart';
import 'privacy_security_screen.dart';
import 'terms_policy_screen.dart';

abstract final class _ProfileText {
  static const String exitGuestModeTitle = 'Exit Guest Mode';
  static const String exitGuestDialogTitle = 'Exit Guest Mode?';
  static const String exitGuestDialogDescription =
      'You will return to the sign-in screen. Your locally saved scans, '
      'history, materials, and folders will remain on this device.';

  static const String cancelLabel = 'Cancel';
  static const String exitLabel = 'Exit';
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() {
    return _ProfileScreenState();
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
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

    _loadUser();
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
            borderRadius: BorderRadius.all(Radius.circular(18)),
            side: BorderSide(color: ProfileStyles.outlineColor),
          ),
          title: const Text(_ProfileText.exitGuestDialogTitle),
          content: const Text(_ProfileText.exitGuestDialogDescription),
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
    return Scaffold(
      backgroundColor: ProfileStyles.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: ProfileStyles.primaryColor,
          onRefresh: _loadUser,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: ProfileStyles.screenPadding,
            children: <Widget>[
              _buildProfileIdentity(),
              const SizedBox(height: ProfileStyles.menuTopSpacing),
              _ProfileMenuGroup(
                children: <Widget>[
                  _ProfileMenuItem(
                    icon: ProfileStyles.accountInformationIcon,
                    title: ProfileStyles.accountInformationTitle,
                    onPressed: _openAccountInformation,
                  ),
                  const _ProfileMenuDivider(),
                  _ProfileMenuItem(
                    icon: ProfileStyles.aboutTactileLensIcon,
                    title: ProfileStyles.aboutTactileLensTitle,
                    onPressed: _openAboutTactileLens,
                  ),
                  const _ProfileMenuDivider(),
                  _ProfileMenuItem(
                    icon: ProfileStyles.termsIcon,
                    title: ProfileStyles.termsTitle,
                    onPressed: _openTermsPolicy,
                  ),
                ],
              ),
              const SizedBox(height: ProfileStyles.menuGroupSpacing),
              _ProfileMenuGroup(
                children: <Widget>[
                  _ProfileMenuItem(
                    icon: ProfileStyles.settingsIcon,
                    title: ProfileStyles.settingsTitle,
                    onPressed: _openSettings,
                  ),
                  const _ProfileMenuDivider(),
                  _ProfileMenuItem(
                    icon: ProfileStyles.privacyIcon,
                    title: ProfileStyles.privacyTitle,
                    onPressed: _openPrivacySecurity,
                  ),
                ],
              ),
              const SizedBox(height: ProfileStyles.menuGroupSpacing),
              _ProfileMenuGroup(
                children: <Widget>[
                  _ProfileMenuItem(
                    icon: ProfileStyles.logoutIcon,
                    title: _isGuest
                        ? _ProfileText.exitGuestModeTitle
                        : ProfileStyles.logoutTitle,
                    iconColor: ProfileStyles.logoutColor,
                    titleStyle: ProfileStyles.logoutTitleStyle,
                    arrowColor: ProfileStyles.logoutColor,
                    iconBackgroundColor:
                        ProfileStyles.logoutIconBackgroundColor,
                    onPressed: () {
                      _requestSessionExit();
                    },
                  ),
                ],
              ),
              const SizedBox(height: ProfileStyles.bottomSpacing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileIdentity() {
    if (_isLoadingProfile) {
      return Container(
        width: double.infinity,
        height: ProfileStyles.profileLoadingHeight,
        decoration: const BoxDecoration(
          color: ProfileStyles.surfaceColor,
          borderRadius: ProfileStyles.profileContainerRadius,
          border: ProfileStyles.cardBorder,
        ),
        child: const Center(
          child: CircularProgressIndicator(color: ProfileStyles.primaryColor),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: ProfileStyles.profileContainerPadding,
      decoration: const BoxDecoration(
        color: ProfileStyles.surfaceColor,
        borderRadius: ProfileStyles.profileContainerRadius,
        border: ProfileStyles.cardBorder,
      ),
      child: Column(
        children: <Widget>[
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Container(
                width: ProfileStyles.profileAvatarSize,
                height: ProfileStyles.profileAvatarSize,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: ProfileStyles.profileAvatarBackgroundColor,
                  shape: BoxShape.circle,
                  border: ProfileStyles.avatarBorder,
                ),
                child: const Icon(
                  ProfileStyles.profileAvatarIcon,
                  size: ProfileStyles.profileAvatarIconSize,
                  color: ProfileStyles.profileAvatarIconColor,
                ),
              ),
              Positioned(
                right: ProfileStyles.editButtonRight,
                bottom: ProfileStyles.editButtonBottom,
                child: Material(
                  color: ProfileStyles.surfaceColor,
                  shape: const CircleBorder(
                    side: BorderSide(color: ProfileStyles.outlineColor),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _openAccountInformation,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: ProfileStyles.editButtonSize,
                      height: ProfileStyles.editButtonSize,
                      child: Icon(
                        ProfileStyles.editIcon,
                        size: ProfileStyles.editIconSize,
                        color: ProfileStyles.primaryBrightColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ProfileStyles.profileNameSpacing),
          Text(
            _displayName,
            textAlign: TextAlign.center,
            style: ProfileStyles.profileNameStyle,
          ),
          if (!_isGuest && _email.isNotEmpty) ...<Widget>[
            const SizedBox(height: ProfileStyles.profileEmailSpacing),
            Text(
              _email,
              textAlign: TextAlign.center,
              style: ProfileStyles.profileEmailStyle,
            ),
          ],
          const SizedBox(height: ProfileStyles.profileRoleSpacing),
          Container(
            padding: ProfileStyles.roleBadgePadding,
            decoration: const BoxDecoration(
              color: ProfileStyles.roleBadgeBackgroundColor,
              borderRadius: ProfileStyles.roleBadgeRadius,
              border: ProfileStyles.roleBadgeBorder,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  ProfileStyles.roleIcon,
                  size: ProfileStyles.roleIconSize,
                  color: ProfileStyles.primaryBrightColor,
                ),
                const SizedBox(width: ProfileStyles.roleIconSpacing),
                Flexible(
                  child: Text(
                    _displayRole,
                    textAlign: TextAlign.center,
                    style: ProfileStyles.roleBadgeTextStyle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuGroup extends StatelessWidget {
  const _ProfileMenuGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: ProfileStyles.surfaceColor,
        borderRadius: ProfileStyles.menuRadius,
        border: ProfileStyles.cardBorder,
        boxShadow: ProfileStyles.cardShadow,
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onPressed,
    this.iconColor = ProfileStyles.primaryBrightColor,
    this.arrowColor = ProfileStyles.primaryBrightColor,
    this.iconBackgroundColor = ProfileStyles.menuIconBackgroundColor,
    this.titleStyle = ProfileStyles.menuTitleStyle,
  });

  final IconData icon;
  final String title;
  final VoidCallback onPressed;
  final Color iconColor;
  final Color arrowColor;
  final Color iconBackgroundColor;
  final TextStyle titleStyle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ProfileStyles.surfaceColor,
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
                  border: ProfileStyles.smallContainerBorder,
                ),
                child: Icon(
                  icon,
                  size: ProfileStyles.menuIconSize,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: ProfileStyles.menuContentSpacing),
              Expanded(child: Text(title, style: titleStyle)),
              Icon(
                ProfileStyles.menuArrowIcon,
                size: ProfileStyles.menuArrowSize,
                color: arrowColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuDivider extends StatelessWidget {
  const _ProfileMenuDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: ProfileStyles.dividerHeight,
      indent: ProfileStyles.dividerIndent,
      endIndent: ProfileStyles.dividerEndIndent,
      color: ProfileStyles.dividerColor,
    );
  }
}
