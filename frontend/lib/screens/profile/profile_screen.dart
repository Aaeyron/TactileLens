import 'package:flutter/material.dart';

import '../../styles/screens/profile/profile_screen_styles.dart';
import '../../utils/session_manager.dart';
import '../../widgets/profile/logout_dialog.dart';
import 'about_tactilelens_screen.dart';
import 'account_information_screen.dart';
import 'privacy_security_screen.dart';
import 'terms_policy_screen.dart';

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

  void _requestLogout() {
    showLogoutDialog(context);
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
              _buildBrandHeader(),
              const SizedBox(height: ProfileStyles.profileTopSpacing),
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
                    title: ProfileStyles.logoutTitle,
                    iconColor: ProfileStyles.logoutColor,
                    titleStyle: ProfileStyles.logoutTitleStyle,
                    arrowColor: ProfileStyles.logoutColor,
                    iconBackgroundColor:
                        ProfileStyles.logoutIconBackgroundColor,
                    onPressed: _requestLogout,
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

  Widget _buildBrandHeader() {
    return Row(
      children: <Widget>[
        ClipRRect(
          borderRadius: ProfileStyles.logoRadius,
          child: Image.asset(
            ProfileStyles.logoAsset,
            width: ProfileStyles.logoSize,
            height: ProfileStyles.logoSize,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: ProfileStyles.logoTextSpacing),
        const Expanded(
          child: Text(ProfileStyles.appName, style: ProfileStyles.appNameStyle),
        ),
        Container(
          width: ProfileStyles.headerIconContainerSize,
          height: ProfileStyles.headerIconContainerSize,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: ProfileStyles.surfaceColor,
            shape: BoxShape.circle,
            border: ProfileStyles.smallContainerBorder,
            boxShadow: ProfileStyles.smallContainerShadow,
          ),
          child: const Icon(
            ProfileStyles.profileHeaderIcon,
            size: ProfileStyles.headerIconSize,
            color: ProfileStyles.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileIdentity() {
    if (_isLoadingProfile) {
      return const SizedBox(
        height: ProfileStyles.profileLoadingHeight,
        child: Center(
          child: CircularProgressIndicator(color: ProfileStyles.primaryColor),
        ),
      );
    }

    return Column(
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
                boxShadow: ProfileStyles.avatarShadow,
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
                elevation: ProfileStyles.editButtonElevation,
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
              Text(_displayRole, style: ProfileStyles.roleBadgeTextStyle),
            ],
          ),
        ),
      ],
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
