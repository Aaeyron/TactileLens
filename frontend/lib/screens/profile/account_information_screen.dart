import 'package:flutter/material.dart';

import '../../styles/screens/profile/account_information_screen_styles.dart';
import '../../utils/session_manager.dart';
import 'privacy_security_screen.dart';

class AccountInformationScreen extends StatefulWidget {
  const AccountInformationScreen({super.key});

  @override
  State<AccountInformationScreen> createState() {
    return _AccountInformationScreenState();
  }
}

class _AccountInformationScreenState
    extends State<AccountInformationScreen> {
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _role = '';
  String _guestNickname = '';

  bool _isGuest = false;
  bool _isLoading = true;

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

      final String role =
          await SessionManager.getRole() ?? '';

      if (!mounted) {
        return;
      }

      setState(() {
        _isGuest = true;
        _guestNickname = guestNickname.trim();
        _role = role.trim();
        _isLoading = false;
      });

      return;
    }

    final String firstName =
        await SessionManager.getFirstName() ?? '';

    final String lastName =
        await SessionManager.getLastName() ?? '';

    final String email =
        await SessionManager.getEmail() ?? '';

    final String role =
        await SessionManager.getRole() ?? '';

    if (!mounted) {
      return;
    }

    setState(() {
      _isGuest = false;
      _firstName = firstName.trim();
      _lastName = lastName.trim();
      _email = email.trim();
      _role = role.trim();
      _isLoading = false;
    });
  }

  String get _displayName {
    if (_isGuest) {
      return _guestNickname.isEmpty
          ? AccountInformationStyles.defaultGuestName
          : _guestNickname;
    }

    final String fullName = <String>[
      _firstName,
      _lastName,
    ].where((String value) => value.isNotEmpty).join(' ');

    return fullName.isEmpty
        ? AccountInformationStyles.defaultUserName
        : fullName;
  }

  String get _displayEmail {
    if (_isGuest) {
      return AccountInformationStyles.guestEmailDescription;
    }

    return _email.isEmpty
        ? AccountInformationStyles.unavailableValue
        : _email;
  }

  String get _displayRole {
    final String normalizedRole = _role.trim();

    if (normalizedRole.isEmpty) {
      return AccountInformationStyles.defaultRole;
    }

    return '${normalizedRole[0].toUpperCase()}'
        '${normalizedRole.substring(1).toLowerCase()}';
  }

  String get _initial {
    final String name = _displayName.trim();

    if (name.isEmpty) {
      return AccountInformationStyles.defaultInitial;
    }

    return name[0].toUpperCase();
  }

  String get _accountType {
    return _isGuest
        ? AccountInformationStyles.guestAccountType
        : AccountInformationStyles.registeredAccountType;
  }

  String get _storageMode {
    return _isGuest
        ? AccountInformationStyles.localStorageMode
        : AccountInformationStyles.hybridStorageMode;
  }

  void _showUnavailableMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: AccountInformationStyles.snackBarDuration,
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              AccountInformationStyles.primaryColor,
          margin: AccountInformationStyles.snackBarMargin,
          shape: const RoundedRectangleBorder(
            borderRadius:
                AccountInformationStyles.snackBarRadius,
          ),
          content: Text(
            message,
            style:
                AccountInformationStyles.snackBarTextStyle,
          ),
        ),
      );
  }

  void _editPersonalDetails() {
    _showUnavailableMessage(
      AccountInformationStyles.editUnavailableMessage,
    );
  }

  void _changePassword() {
    _showUnavailableMessage(
      AccountInformationStyles.passwordUnavailableMessage,
    );
  }

  void _changeRole() {
    _showUnavailableMessage(
      AccountInformationStyles.roleUnavailableMessage,
    );
  }

  void _changeLanguage() {
    _showUnavailableMessage(
      AccountInformationStyles.languageUnavailableMessage,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AccountInformationStyles.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AccountInformationStyles.primaryColor,
          onRefresh: _loadUser,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                AccountInformationStyles.screenPadding,
            children: <Widget>[
              _buildHeader(),
              const SizedBox(
                height: AccountInformationStyles
                    .headerBottomSpacing,
              ),
              if (_isLoading)
                const _AccountLoadingState()
              else ...<Widget>[
                _buildProfileSummary(),
                const SizedBox(
                  height: AccountInformationStyles
                      .sectionSpacing,
                ),
                _buildPersonalDetails(),
                const SizedBox(
                  height: AccountInformationStyles
                      .sectionSpacing,
                ),
                _buildAdditionalInformation(),
                const SizedBox(
                  height: AccountInformationStyles
                      .sectionSpacing,
                ),
                _buildSecurityBanner(),
              ],
              const SizedBox(
                height:
                    AccountInformationStyles.bottomSpacing,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: <Widget>[
        Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip:
                    AccountInformationStyles.backTooltip,
                onPressed: () {
                  Navigator.of(context).maybePop();
                },
                style:
                    AccountInformationStyles.backButtonStyle,
                icon: const Icon(
                  AccountInformationStyles.backIcon,
                  size:
                      AccountInformationStyles.backIconSize,
                ),
              ),
            ),
            const Padding(
              padding: AccountInformationStyles
                  .headerTitlePadding,
              child: Text(
                AccountInformationStyles.screenTitle,
                textAlign: TextAlign.center,
                style: AccountInformationStyles
                    .screenTitleStyle,
              ),
            ),
          ],
        ),
        const SizedBox(
          height: AccountInformationStyles
              .headerDescriptionSpacing,
        ),
        const Text(
          AccountInformationStyles.screenDescription,
          textAlign: TextAlign.center,
          style:
              AccountInformationStyles.headerDescriptionStyle,
        ),
      ],
    );
  }

  Widget _buildProfileSummary() {
    return Container(
      width: double.infinity,
      padding:
          AccountInformationStyles.profileCardPadding,
      decoration: const BoxDecoration(
        color: AccountInformationStyles.surfaceColor,
        borderRadius:
            AccountInformationStyles.cardRadius,
        border: AccountInformationStyles.cardBorder,
        boxShadow: AccountInformationStyles.cardShadow,
      ),
      child: Row(
        children: <Widget>[
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Container(
                width: AccountInformationStyles
                    .profileAvatarSize,
                height: AccountInformationStyles
                    .profileAvatarSize,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AccountInformationStyles
                      .avatarBackgroundColor,
                  shape: BoxShape.circle,
                  border:
                      AccountInformationStyles.avatarBorder,
                ),
                child: Text(
                  _initial,
                  style: AccountInformationStyles
                      .avatarTextStyle,
                ),
              ),
              Positioned(
                right: AccountInformationStyles
                    .editAvatarRight,
                bottom: AccountInformationStyles
                    .editAvatarBottom,
                child: Material(
                  color:
                      AccountInformationStyles.surfaceColor,
                  shape: const CircleBorder(
                    side: BorderSide(
                      color: AccountInformationStyles
                          .outlineColor,
                    ),
                  ),
                  elevation: AccountInformationStyles
                      .editAvatarElevation,
                  child: InkWell(
                    onTap: _editPersonalDetails,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: AccountInformationStyles
                          .editAvatarSize,
                      height: AccountInformationStyles
                          .editAvatarSize,
                      child: Icon(
                        AccountInformationStyles.editIcon,
                        size: AccountInformationStyles
                            .editAvatarIconSize,
                        color: AccountInformationStyles
                            .primaryBrightColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            width: AccountInformationStyles
                .profileContentSpacing,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AccountInformationStyles
                      .profileNameStyle,
                ),
                const SizedBox(
                  height: AccountInformationStyles
                      .profileRoleSpacing,
                ),
                Container(
                  padding: AccountInformationStyles
                      .roleBadgePadding,
                  decoration: const BoxDecoration(
                    color: AccountInformationStyles
                        .roleBadgeBackgroundColor,
                    borderRadius:
                        AccountInformationStyles
                            .roleBadgeRadius,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        AccountInformationStyles
                            .roleIcon,
                        size: AccountInformationStyles
                            .roleIconSize,
                        color:
                            AccountInformationStyles
                                .primaryBrightColor,
                      ),
                      const SizedBox(
                        width: AccountInformationStyles
                            .roleIconSpacing,
                      ),
                      Flexible(
                        child: Text(
                          _displayRole,
                          overflow: TextOverflow.ellipsis,
                          style:
                              AccountInformationStyles
                                  .roleBadgeTextStyle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: AccountInformationStyles
                      .profileEmailSpacing,
                ),
                Row(
                  children: <Widget>[
                    const Icon(
                      AccountInformationStyles.emailIcon,
                      size: AccountInformationStyles
                          .profileEmailIconSize,
                      color: AccountInformationStyles
                          .primaryBrightColor,
                    ),
                    const SizedBox(
                      width: AccountInformationStyles
                          .profileEmailIconSpacing,
                    ),
                    Expanded(
                      child: Text(
                        _displayEmail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AccountInformationStyles
                            .profileEmailStyle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetails() {
    return _InformationSection(
      icon:
          AccountInformationStyles.personalDetailsIcon,
      title:
          AccountInformationStyles.personalDetailsTitle,
      action: _isGuest
          ? null
          : _SectionActionButton(
              icon: AccountInformationStyles.editIcon,
              label:
                  AccountInformationStyles.editButtonTitle,
              onPressed: _editPersonalDetails,
            ),
      children: <Widget>[
        if (_isGuest)
          _InformationTile(
            icon: AccountInformationStyles.nicknameIcon,
            title: AccountInformationStyles.nicknameTitle,
            value: _displayName,
          )
        else
          _InformationTile(
            icon: AccountInformationStyles.fullNameIcon,
            title: AccountInformationStyles.fullNameTitle,
            value: _displayName,
          ),
        const _InformationDivider(),
        _InformationTile(
          icon: AccountInformationStyles.emailIcon,
          title: AccountInformationStyles.emailTitle,
          value: _displayEmail,
        ),
        if (!_isGuest) ...<Widget>[
          const _InformationDivider(),
          _InformationTile(
            icon: AccountInformationStyles.passwordIcon,
            title:
                AccountInformationStyles.passwordTitle,
            value:
                AccountInformationStyles.maskedPassword,
            action: _InformationActionButton(
              label:
                  AccountInformationStyles.changeLabel,
              onPressed: _changePassword,
            ),
          ),
        ],
        const _InformationDivider(),
        _InformationTile(
          icon: AccountInformationStyles.roleValueIcon,
          title: AccountInformationStyles.roleTitle,
          value: _displayRole,
          action: _InformationActionButton(
            label: AccountInformationStyles.changeLabel,
            onPressed: _changeRole,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInformation() {
    return _InformationSection(
      icon:
          AccountInformationStyles.additionalInformationIcon,
      title: AccountInformationStyles
          .additionalInformationTitle,
      children: <Widget>[
        _InformationTile(
          icon: AccountInformationStyles.accountTypeIcon,
          title:
              AccountInformationStyles.accountTypeTitle,
          value: _accountType,
        ),
        const _InformationDivider(),
        _InformationTile(
          icon: AccountInformationStyles.storageIcon,
          title: AccountInformationStyles.storageTitle,
          value: _storageMode,
        ),
        const _InformationDivider(),
        _InformationTile(
          icon: AccountInformationStyles.languageIcon,
          title: AccountInformationStyles.languageTitle,
          value:
              AccountInformationStyles.defaultLanguage,
          action: _InformationActionButton(
            label: AccountInformationStyles.changeLabel,
            onPressed: _changeLanguage,
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityBanner() {
    return Material(
      color: AccountInformationStyles
          .securityBackgroundColor,
      borderRadius:
          AccountInformationStyles.cardRadius,
      child: InkWell(
        onTap: _openPrivacySecurity,
        borderRadius:
            AccountInformationStyles.cardRadius,
        child: Container(
          padding:
              AccountInformationStyles.securityPadding,
          decoration: const BoxDecoration(
            borderRadius:
                AccountInformationStyles.cardRadius,
            border:
                AccountInformationStyles.securityBorder,
            boxShadow:
                AccountInformationStyles.securityShadow,
          ),
          child: const Row(
            children: <Widget>[
              Icon(
                AccountInformationStyles.securityIcon,
                size: AccountInformationStyles
                    .securityIconSize,
                color:
                    AccountInformationStyles.primaryColor,
              ),
              SizedBox(
                width: AccountInformationStyles
                    .securityContentSpacing,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AccountInformationStyles
                          .securityTitle,
                      style: AccountInformationStyles
                          .securityTitleStyle,
                    ),
                    SizedBox(
                      height: AccountInformationStyles
                          .securityDescriptionSpacing,
                    ),
                    Text(
                      AccountInformationStyles
                          .securityDescription,
                      style: AccountInformationStyles
                          .securityDescriptionStyle,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: AccountInformationStyles
                    .securityContentSpacing,
              ),
              Icon(
                AccountInformationStyles.forwardIcon,
                size: AccountInformationStyles
                    .forwardIconSize,
                color: AccountInformationStyles
                    .primaryBrightColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InformationSection extends StatelessWidget {
  const _InformationSection({
    required this.icon,
    required this.title,
    required this.children,
    this.action,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AccountInformationStyles.surfaceColor,
        borderRadius:
            AccountInformationStyles.cardRadius,
        border: AccountInformationStyles.cardBorder,
        boxShadow: AccountInformationStyles.cardShadow,
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: AccountInformationStyles
                .sectionHeaderPadding,
            child: Row(
              children: <Widget>[
                Icon(
                  icon,
                  size: AccountInformationStyles
                      .sectionHeaderIconSize,
                  color: AccountInformationStyles
                      .primaryBrightColor,
                ),
                const SizedBox(
                  width: AccountInformationStyles
                      .sectionHeaderIconSpacing,
                ),
                Expanded(
                  child: Text(
                    title,
                    style: AccountInformationStyles
                        .sectionTitleStyle,
                  ),
                ),
                ?action,
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _InformationTile extends StatelessWidget {
  const _InformationTile({
    required this.icon,
    required this.title,
    required this.value,
    this.action,
  });

  final IconData icon;
  final String title;
  final String value;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          AccountInformationStyles.informationTilePadding,
      child: Row(
        children: <Widget>[
          Container(
            width: AccountInformationStyles
                .informationIconContainerSize,
            height: AccountInformationStyles
                .informationIconContainerSize,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AccountInformationStyles
                  .informationIconBackgroundColor,
              borderRadius:
                  AccountInformationStyles
                      .informationIconRadius,
            ),
            child: Icon(
              icon,
              size: AccountInformationStyles
                  .informationIconSize,
              color: AccountInformationStyles
                  .primaryBrightColor,
            ),
          ),
          const SizedBox(
            width: AccountInformationStyles
                .informationContentSpacing,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AccountInformationStyles
                      .informationTitleStyle,
                ),
                const SizedBox(
                  height: AccountInformationStyles
                      .informationValueSpacing,
                ),
                Text(
                  value,
                  style: AccountInformationStyles
                      .informationValueStyle,
                ),
              ],
            ),
          ),
          if (action != null) ...<Widget>[
            const SizedBox(
              width: AccountInformationStyles
                  .informationActionSpacing,
            ),
            action!,
          ],
        ],
      ),
    );
  }
}

class _InformationDivider extends StatelessWidget {
  const _InformationDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: AccountInformationStyles.dividerHeight,
      indent: AccountInformationStyles.dividerIndent,
      endIndent:
          AccountInformationStyles.dividerEndIndent,
      color: AccountInformationStyles.dividerColor,
    );
  }
}

class _SectionActionButton extends StatelessWidget {
  const _SectionActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style:
          AccountInformationStyles.sectionActionButtonStyle,
      icon: Icon(
        icon,
        size:
            AccountInformationStyles.actionButtonIconSize,
      ),
      label: Text(label),
    );
  }
}

class _InformationActionButton extends StatelessWidget {
  const _InformationActionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style:
          AccountInformationStyles.informationActionButtonStyle,
      child: Text(label),
    );
  }
}

class _AccountLoadingState extends StatelessWidget {
  const _AccountLoadingState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: AccountInformationStyles.loadingHeight,
      child: Center(
        child: CircularProgressIndicator(
          color: AccountInformationStyles.primaryColor,
        ),
      ),
    );
  }
}