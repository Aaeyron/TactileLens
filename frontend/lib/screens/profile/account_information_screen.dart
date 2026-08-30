import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/guest/guest_data_service.dart';
import '../../styles/screens/profile/account_information_screen_styles.dart';
import '../../utils/session_manager.dart';
import '../auth/auth_screen.dart';
import 'privacy_security_screen.dart';

class AccountInformationScreen extends StatefulWidget {
  const AccountInformationScreen({super.key});

  @override
  State<AccountInformationScreen> createState() {
    return _AccountInformationScreenState();
  }
}

class _AccountInformationScreenState extends State<AccountInformationScreen>
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _configureEntranceAnimation();
    _loadUser();

    Future<void>.delayed(AccountInformationStyles.entranceDelay, () {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  void _configureEntranceAnimation() {
    _entranceController = AnimationController(
      vsync: this,
      duration: AccountInformationStyles.entranceDuration,
    );

    final CurvedAnimation entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: AccountInformationStyles.entranceCurve,
    );

    _entranceOpacity = entranceAnimation;

    _entrancePosition = Tween<Offset>(
      begin: AccountInformationStyles.entranceBeginOffset,
      end: Offset.zero,
    ).animate(entranceAnimation);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    if (mounted && !_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    final bool isGuest = await SessionManager.isGuest();

    if (isGuest) {
      final String guestNickname =
          await SessionManager.getGuestNickname() ?? '';

      final String role = await SessionManager.getGuestRole() ?? '';

      if (!mounted) {
        return;
      }

      setState(() {
        _isGuest = true;
        _guestNickname = guestNickname.trim();
        _firstName = '';
        _lastName = '';
        _email = '';
        _role = role.trim();
        _isLoading = false;
      });

      return;
    }

    final List<Object?> userValues =
        await Future.wait<Object?>(<Future<Object?>>[
          SessionManager.getFirstName(),
          SessionManager.getLastName(),
          SessionManager.getEmail(),
          SessionManager.getRole(),
        ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _isGuest = false;
      _firstName = (userValues[0] as String? ?? '').trim();
      _lastName = (userValues[1] as String? ?? '').trim();
      _email = (userValues[2] as String? ?? '').trim();
      _role = (userValues[3] as String? ?? '').trim();
      _guestNickname = '';
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

    return _email.isEmpty ? AccountInformationStyles.unavailableValue : _email;
  }

  String get _displayRole {
    final String normalizedRole = _role.trim();

    if (normalizedRole.isEmpty) {
      return AccountInformationStyles.defaultRole;
    }

    return '${normalizedRole[0].toUpperCase()}'
        '${normalizedRole.substring(1).toLowerCase()}';
  }

  String get _initials {
    final List<String> nameParts = _displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((String value) => value.isNotEmpty)
        .toList(growable: false);

    if (nameParts.isEmpty) {
      return AccountInformationStyles.defaultInitial;
    }

    if (nameParts.length == 1) {
      return nameParts.first[0].toUpperCase();
    }

    return '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase();
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

  void _openPrivacySecurity() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const PrivacySecurityScreen();
        },
      ),
    );
  }

  Future<void> _openGuestProfileEditor() async {
    if (!_isGuest || _isLoading) {
      return;
    }

    final bool? wasUpdated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return _GuestProfileEditorSheet(
          initialNickname: _guestNickname,
          initialRole: _role,
        );
      },
    );

    if (wasUpdated != true || !mounted) {
      return;
    }

    await _loadUser();

    if (!mounted) {
      return;
    }

    _showMessage(AccountInformationStyles.guestProfileUpdatedMessage);
  }

  Future<void> _confirmDeleteGuestData() async {
    if (!_isGuest || _isLoading) {
      return;
    }

    final bool? wasDeleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const _DeleteGuestDataDialog();
      },
    );

    if (wasDeleted != true || !mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const AuthScreen();
        },
      ),
      (Route<dynamic> route) => false,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AccountInformationStyles.primaryColor,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AccountInformationStyles.backgroundColor,
        body: FadeTransition(
          opacity: _entranceOpacity,
          child: SlideTransition(
            position: _entrancePosition,
            child: RefreshIndicator(
              color: AccountInformationStyles.primaryColor,
              backgroundColor: AccountInformationStyles.surfaceColor,
              onRefresh: _loadUser,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: <Widget>[
                  SliverToBoxAdapter(child: _buildHeader(context)),
                  SliverPadding(
                    padding: AccountInformationStyles.contentPadding,
                    sliver: SliverList(
                      delegate: SliverChildListDelegate.fixed(<Widget>[
                        if (_isLoading)
                          const _AccountLoadingState()
                        else ...<Widget>[
                          _buildIdentityCard(),
                          const SizedBox(
                            height: AccountInformationStyles.sectionSpacing,
                          ),
                          if (_isGuest) ...<Widget>[
                            _buildGuestInformation(),
                            const SizedBox(
                              height: AccountInformationStyles.sectionSpacing,
                            ),
                          ],
                          _buildPersonalInformation(),
                          const SizedBox(
                            height: AccountInformationStyles.sectionSpacing,
                          ),
                          _buildAccountInformation(),
                          const SizedBox(
                            height: AccountInformationStyles.sectionSpacing,
                          ),
                          _buildPrivacyCard(),
                          if (_isGuest) ...<Widget>[
                            const SizedBox(
                              height: AccountInformationStyles.sectionSpacing,
                            ),
                            _buildGuestDataCard(),
                          ],
                        ],
                        const SizedBox(
                          height: AccountInformationStyles.bottomSpacing,
                        ),
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

  Widget _buildHeader(BuildContext context) {
    final double statusBarHeight = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height:
          statusBarHeight +
          AccountInformationStyles.headerHeight +
          AccountInformationStyles.avatarOverlapSpace,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: double.infinity,
            height: statusBarHeight + AccountInformationStyles.headerHeight,
            padding: EdgeInsets.fromLTRB(
              AccountInformationStyles.headerHorizontalPadding,
              statusBarHeight + AccountInformationStyles.headerTopPadding,
              AccountInformationStyles.headerHorizontalPadding,
              AccountInformationStyles.headerBottomPadding,
            ),
            decoration: const BoxDecoration(
              gradient: AccountInformationStyles.headerGradient,
              borderRadius: AccountInformationStyles.headerRadius,
            ),
            child: Stack(
              children: <Widget>[
                const Positioned(
                  right: AccountInformationStyles.decorationRight,
                  top: AccountInformationStyles.decorationTop,
                  child: _HeaderBrailleDecoration(),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        IconButton(
                          tooltip: AccountInformationStyles.backTooltip,
                          onPressed: () {
                            Navigator.of(context).maybePop();
                          },
                          style: AccountInformationStyles.backButtonStyle,
                          icon: const Icon(
                            AccountInformationStyles.backIcon,
                            size: AccountInformationStyles.backIconSize,
                          ),
                        ),
                        const SizedBox(
                          width: AccountInformationStyles.headerBackSpacing,
                        ),
                        const Expanded(
                          child: Text(
                            AccountInformationStyles.screenTitle,
                            style: AccountInformationStyles.headerTitleStyle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: AccountInformationStyles.headerTextSpacing,
                    ),
                    const Padding(
                      padding:
                          AccountInformationStyles.headerDescriptionPadding,
                      child: Text(
                        AccountInformationStyles.screenDescription,
                        style: AccountInformationStyles.headerDescriptionStyle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: AccountInformationStyles.avatarHorizontalInset,
            right: AccountInformationStyles.avatarHorizontalInset,
            bottom: AccountInformationStyles.avatarBottom,
            child: Center(child: _buildAvatar()),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: AccountInformationStyles.avatarOuterSize,
      height: AccountInformationStyles.avatarOuterSize,
      padding: AccountInformationStyles.avatarOuterPadding,
      decoration: const BoxDecoration(
        color: AccountInformationStyles.surfaceColor,
        shape: BoxShape.circle,
        boxShadow: AccountInformationStyles.avatarShadow,
      ),
      child: Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          gradient: AccountInformationStyles.avatarGradient,
          shape: BoxShape.circle,
        ),
        child: Text(
          _isLoading ? AccountInformationStyles.defaultInitial : _initials,
          style: AccountInformationStyles.avatarTextStyle,
        ),
      ),
    );
  }

  Widget _buildIdentityCard() {
    return Container(
      width: double.infinity,
      padding: AccountInformationStyles.identityCardPadding,
      decoration: const BoxDecoration(
        color: AccountInformationStyles.surfaceColor,
        borderRadius: AccountInformationStyles.cardRadius,
        border: AccountInformationStyles.cardBorder,
        boxShadow: AccountInformationStyles.cardShadow,
      ),
      child: Column(
        children: <Widget>[
          Text(
            _displayName,
            textAlign: TextAlign.center,
            style: AccountInformationStyles.profileNameStyle,
          ),
          const SizedBox(height: AccountInformationStyles.profileRoleSpacing),
          Container(
            padding: AccountInformationStyles.roleBadgePadding,
            decoration: const BoxDecoration(
              color: AccountInformationStyles.roleBadgeBackgroundColor,
              borderRadius: AccountInformationStyles.roleBadgeRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  AccountInformationStyles.roleIcon,
                  size: AccountInformationStyles.roleIconSize,
                  color: AccountInformationStyles.primaryColor,
                ),
                const SizedBox(width: AccountInformationStyles.roleIconSpacing),
                Text(
                  _displayRole,
                  style: AccountInformationStyles.roleBadgeTextStyle,
                ),
              ],
            ),
          ),
          const SizedBox(height: AccountInformationStyles.profileEmailSpacing),
          Text(
            _displayEmail,
            textAlign: TextAlign.center,
            style: AccountInformationStyles.profileEmailStyle,
          ),
          if (_isGuest) ...<Widget>[
            const SizedBox(
              height: AccountInformationStyles.editGuestButtonSpacing,
            ),
            Tooltip(
              message: AccountInformationStyles.editGuestProfileTooltip,
              child: OutlinedButton.icon(
                onPressed: _openGuestProfileEditor,
                style: AccountInformationStyles.editGuestButtonStyle,
                icon: const Icon(
                  AccountInformationStyles.editGuestIcon,
                  size: 19,
                ),
                label: const Text(
                  AccountInformationStyles.editGuestProfileLabel,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuestInformation() {
    return const _NoticeCard(
      icon: AccountInformationStyles.offlineIcon,
      title: AccountInformationStyles.guestNoticeTitle,
      description: AccountInformationStyles.guestNoticeDescription,
    );
  }

  Widget _buildPersonalInformation() {
    return _InformationCard(
      title: AccountInformationStyles.personalDetailsTitle,
      icon: AccountInformationStyles.personalDetailsIcon,
      children: <Widget>[
        _AccountInformationRow(
          icon: _isGuest
              ? AccountInformationStyles.nicknameIcon
              : AccountInformationStyles.fullNameIcon,
          label: _isGuest
              ? AccountInformationStyles.nicknameTitle
              : AccountInformationStyles.fullNameTitle,
          value: _displayName,
        ),
        const _InformationDivider(),
        _AccountInformationRow(
          icon: AccountInformationStyles.emailIcon,
          label: AccountInformationStyles.emailTitle,
          value: _displayEmail,
        ),
        const _InformationDivider(),
        _AccountInformationRow(
          icon: AccountInformationStyles.roleValueIcon,
          label: AccountInformationStyles.roleTitle,
          value: _displayRole,
        ),
      ],
    );
  }

  Widget _buildAccountInformation() {
    return _InformationCard(
      title: AccountInformationStyles.accountDetailsTitle,
      icon: AccountInformationStyles.accountTypeIcon,
      children: <Widget>[
        _AccountInformationRow(
          icon: AccountInformationStyles.accountTypeIcon,
          label: AccountInformationStyles.accountTypeTitle,
          value: _accountType,
        ),
        const _InformationDivider(),
        _AccountInformationRow(
          icon: AccountInformationStyles.storageIcon,
          label: AccountInformationStyles.storageTitle,
          value: _storageMode,
        ),
        const _InformationDivider(),
        const _AccountInformationRow(
          icon: AccountInformationStyles.languageIcon,
          label: AccountInformationStyles.languageTitle,
          value: AccountInformationStyles.defaultLanguage,
        ),
      ],
    );
  }

  Widget _buildPrivacyCard() {
    return Material(
      color: AccountInformationStyles.securityBackgroundColor,
      borderRadius: AccountInformationStyles.cardRadius,
      child: InkWell(
        onTap: _openPrivacySecurity,
        borderRadius: AccountInformationStyles.cardRadius,
        child: Container(
          padding: AccountInformationStyles.securityPadding,
          decoration: const BoxDecoration(
            borderRadius: AccountInformationStyles.cardRadius,
            border: AccountInformationStyles.securityBorder,
          ),
          child: const Row(
            children: <Widget>[
              _InformationIcon(icon: AccountInformationStyles.securityIcon),
              SizedBox(width: AccountInformationStyles.rowContentSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AccountInformationStyles.securityTitle,
                      style: AccountInformationStyles.securityTitleStyle,
                    ),
                    SizedBox(
                      height:
                          AccountInformationStyles.securityDescriptionSpacing,
                    ),
                    Text(
                      AccountInformationStyles.securityDescription,
                      style: AccountInformationStyles.securityDescriptionStyle,
                    ),
                  ],
                ),
              ),
              SizedBox(width: AccountInformationStyles.rowActionSpacing),
              Icon(
                AccountInformationStyles.forwardIcon,
                color: AccountInformationStyles.primaryColor,
                size: AccountInformationStyles.forwardIconSize,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestDataCard() {
    return Container(
      width: double.infinity,
      padding: AccountInformationStyles.guestDataCardPadding,
      decoration: const BoxDecoration(
        color: AccountInformationStyles.dangerBackgroundColor,
        borderRadius: AccountInformationStyles.cardRadius,
        border: AccountInformationStyles.guestDataCardBorder,
        boxShadow: AccountInformationStyles.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              _InformationIcon(
                icon: AccountInformationStyles.guestDataIcon,
                color: AccountInformationStyles.dangerColor,
                backgroundColor:
                    AccountInformationStyles.warningBackgroundColor,
              ),
              SizedBox(width: AccountInformationStyles.rowContentSpacing),
              Expanded(
                child: Text(
                  AccountInformationStyles.guestDataSectionTitle,
                  style: AccountInformationStyles.guestDataTitleStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            AccountInformationStyles.deleteGuestDataDescription,
            style: AccountInformationStyles.guestDataDescriptionStyle,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: Tooltip(
              message: AccountInformationStyles.deleteGuestDataTooltip,
              child: TextButton.icon(
                onPressed: _confirmDeleteGuestData,
                style: AccountInformationStyles.deleteGuestDataButtonStyle,
                icon: const Icon(
                  AccountInformationStyles.deleteGuestDataIcon,
                  size: 20,
                ),
                label: const Text(
                  AccountInformationStyles.deleteGuestDataTitle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestProfileEditorSheet extends StatefulWidget {
  const _GuestProfileEditorSheet({
    required this.initialNickname,
    required this.initialRole,
  });

  final String initialNickname;
  final String initialRole;

  @override
  State<_GuestProfileEditorSheet> createState() {
    return _GuestProfileEditorSheetState();
  }
}

class _GuestProfileEditorSheetState extends State<_GuestProfileEditorSheet> {
  late final TextEditingController _nicknameController;

  late String _selectedRole;

  String? _nicknameError;
  String? _saveError;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _nicknameController = TextEditingController(text: widget.initialNickname);

    _selectedRole =
        widget.initialRole.trim().toLowerCase() ==
            AccountInformationStyles.educatorRoleLabel.toLowerCase()
        ? AccountInformationStyles.educatorRoleLabel
        : AccountInformationStyles.studentRoleLabel;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _selectRole(String role) {
    if (_isSaving || role == _selectedRole) {
      return;
    }

    setState(() {
      _selectedRole = role;
      _saveError = null;
    });
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    FocusScope.of(context).unfocus();

    final String nickname = _nicknameController.text.trim();

    if (nickname.isEmpty) {
      setState(() {
        _nicknameError = AccountInformationStyles.nicknameRequiredMessage;
        _saveError = null;
      });

      return;
    }

    if (nickname.length > AccountInformationStyles.nicknameMaximumLength) {
      setState(() {
        _nicknameError = AccountInformationStyles.nicknameTooLongMessage;
        _saveError = null;
      });

      return;
    }

    setState(() {
      _nicknameError = null;
      _saveError = null;
      _isSaving = true;
    });

    try {
      await SessionManager.updateGuestProfile(
        nickname: nickname,
        role: _selectedRole,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saveError = error.message;
        _isSaving = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saveError = AccountInformationStyles.guestProfileUpdateErrorMessage;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets keyboardInsets = MediaQuery.viewInsetsOf(context);

    return AnimatedPadding(
      duration: AccountInformationStyles.guestActionDuration,
      curve: AccountInformationStyles.guestActionCurve,
      padding: keyboardInsets,
      child: Material(
        color: AccountInformationStyles.surfaceColor,
        borderRadius: AccountInformationStyles.guestSheetRadius,
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: AccountInformationStyles.guestSheetPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: AccountInformationStyles.outlineColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const Text(
                  AccountInformationStyles.editGuestProfileTitle,
                  style: AccountInformationStyles.guestSheetTitleStyle,
                ),
                const SizedBox(height: 6),
                const Text(
                  AccountInformationStyles.editGuestProfileDescription,
                  style: AccountInformationStyles.guestSheetDescriptionStyle,
                ),
                const SizedBox(
                  height: AccountInformationStyles.guestSheetSectionSpacing,
                ),
                const Text(
                  AccountInformationStyles.editNicknameLabel,
                  style: AccountInformationStyles.guestFieldLabelStyle,
                ),
                const SizedBox(
                  height: AccountInformationStyles.guestSheetItemSpacing,
                ),
                TextField(
                  controller: _nicknameController,
                  enabled: !_isSaving,
                  maxLength: AccountInformationStyles.nicknameMaximumLength,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    if (_nicknameError != null || _saveError != null) {
                      setState(() {
                        _nicknameError = null;
                        _saveError = null;
                      });
                    }
                  },
                  onSubmitted: (_) {
                    _save();
                  },
                  decoration: AccountInformationStyles
                      .guestNicknameInputDecoration
                      .copyWith(errorText: _nicknameError),
                ),
                const SizedBox(height: 5),
                const Text(
                  AccountInformationStyles.editNicknameHelper,
                  style: AccountInformationStyles.guestFieldHelperStyle,
                ),
                const SizedBox(
                  height: AccountInformationStyles.guestSheetSectionSpacing,
                ),
                const Text(
                  AccountInformationStyles.editRoleLabel,
                  style: AccountInformationStyles.guestFieldLabelStyle,
                ),
                const SizedBox(height: 5),
                const Text(
                  AccountInformationStyles.editRoleDescription,
                  style: AccountInformationStyles.guestFieldHelperStyle,
                ),
                const SizedBox(
                  height: AccountInformationStyles.guestSheetItemSpacing,
                ),
                _GuestRoleOption(
                  title: AccountInformationStyles.studentRoleLabel,
                  description: AccountInformationStyles.studentRoleDescription,
                  icon: AccountInformationStyles.studentRoleIcon,
                  isSelected:
                      _selectedRole ==
                      AccountInformationStyles.studentRoleLabel,
                  enabled: !_isSaving,
                  onPressed: () {
                    _selectRole(AccountInformationStyles.studentRoleLabel);
                  },
                ),
                const SizedBox(
                  height: AccountInformationStyles.guestRoleOptionSpacing,
                ),
                _GuestRoleOption(
                  title: AccountInformationStyles.educatorRoleLabel,
                  description: AccountInformationStyles.educatorRoleDescription,
                  icon: AccountInformationStyles.educatorRoleIcon,
                  isSelected:
                      _selectedRole ==
                      AccountInformationStyles.educatorRoleLabel,
                  enabled: !_isSaving,
                  onPressed: () {
                    _selectRole(AccountInformationStyles.educatorRoleLabel);
                  },
                ),
                if (_saveError != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    _saveError!,
                    style: const TextStyle(
                      color: AccountInformationStyles.dangerColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(
                  height: AccountInformationStyles.guestSheetSectionSpacing,
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextButton(
                        onPressed: _isSaving
                            ? null
                            : () {
                                Navigator.of(context).pop(false);
                              },
                        style:
                            AccountInformationStyles.cancelGuestEditButtonStyle,
                        child: const Text(
                          AccountInformationStyles.cancelEditLabel,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: AccountInformationStyles.guestSheetButtonSpacing,
                    ),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSaving ? null : _save,
                        style:
                            AccountInformationStyles.saveGuestEditButtonStyle,
                        child: _isSaving
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: AccountInformationStyles.surfaceColor,
                                ),
                              )
                            : const Text(
                                AccountInformationStyles.saveGuestProfileLabel,
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuestRoleOption extends StatelessWidget {
  const _GuestRoleOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.enabled,
    required this.onPressed,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      enabled: enabled,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: AccountInformationStyles.guestRoleOptionRadius,
          child: AnimatedContainer(
            duration: AccountInformationStyles.roleSelectionDuration,
            curve: AccountInformationStyles.guestActionCurve,
            padding: AccountInformationStyles.guestRoleOptionPadding,
            decoration: BoxDecoration(
              color: isSelected
                  ? AccountInformationStyles.selectedRoleBackgroundColor
                  : AccountInformationStyles.surfaceColor,
              borderRadius: AccountInformationStyles.guestRoleOptionRadius,
              border: Border.all(
                color: isSelected
                    ? AccountInformationStyles.primaryColor
                    : AccountInformationStyles.outlineColor,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: AccountInformationStyles.guestRoleIconContainerSize,
                  height: AccountInformationStyles.guestRoleIconContainerSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AccountInformationStyles.selectedRoleBackgroundColor
                        : AccountInformationStyles.backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: AccountInformationStyles.guestRoleIconSize,
                    color: AccountInformationStyles.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: AccountInformationStyles.guestRoleTitleStyle,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style:
                            AccountInformationStyles.guestRoleDescriptionStyle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: AccountInformationStyles.roleSelectionDuration,
                  width: AccountInformationStyles.guestRoleCheckSize,
                  height: AccountInformationStyles.guestRoleCheckSize,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AccountInformationStyles.primaryColor
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AccountInformationStyles.primaryColor
                          : AccountInformationStyles.outlineColor,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          AccountInformationStyles.selectedRoleIcon,
                          size: 13,
                          color: AccountInformationStyles.surfaceColor,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteGuestDataDialog extends StatefulWidget {
  const _DeleteGuestDataDialog();

  @override
  State<_DeleteGuestDataDialog> createState() {
    return _DeleteGuestDataDialogState();
  }
}

class _DeleteGuestDataDialogState extends State<_DeleteGuestDataDialog> {
  bool _isDeleting = false;
  String? _errorMessage;

  Future<void> _deleteGuestData() async {
    if (_isDeleting) {
      return;
    }

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await GuestDataService.deleteGuestData();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isDeleting = false;
        _errorMessage = AccountInformationStyles.deleteGuestDataErrorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDeleting,
      child: AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: AccountInformationStyles.deleteDialogRadius,
        ),
        title: const Row(
          children: <Widget>[
            Icon(
              AccountInformationStyles.warningIcon,
              color: AccountInformationStyles.dangerColor,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                AccountInformationStyles.deleteGuestDialogTitle,
                style: AccountInformationStyles.deleteDialogTitleStyle,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              AccountInformationStyles.deleteGuestDialogDescription,
              style: AccountInformationStyles.deleteDialogDescriptionStyle,
            ),
            const SizedBox(height: 12),
            const Text(
              AccountInformationStyles.deleteGuestDialogWarning,
              style: AccountInformationStyles.deleteDialogWarningStyle,
            ),
            if (_errorMessage != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AccountInformationStyles.dangerColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: _isDeleting
                ? null
                : () {
                    Navigator.of(context).pop(false);
                  },
            style: AccountInformationStyles.cancelDeleteButtonStyle,
            child: const Text(AccountInformationStyles.cancelDeleteLabel),
          ),
          FilledButton(
            onPressed: _isDeleting ? null : _deleteGuestData,
            style: AccountInformationStyles.confirmDeleteButtonStyle,
            child: _isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AccountInformationStyles.surfaceColor,
                    ),
                  )
                : const Text(AccountInformationStyles.confirmDeleteLabel),
          ),
        ],
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AccountInformationStyles.surfaceColor,
        borderRadius: AccountInformationStyles.cardRadius,
        border: AccountInformationStyles.cardBorder,
        boxShadow: AccountInformationStyles.cardShadow,
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: AccountInformationStyles.sectionHeaderPadding,
            child: Row(
              children: <Widget>[
                Icon(
                  icon,
                  size: AccountInformationStyles.sectionHeaderIconSize,
                  color: AccountInformationStyles.primaryColor,
                ),
                const SizedBox(
                  width: AccountInformationStyles.sectionHeaderIconSpacing,
                ),
                Expanded(
                  child: Text(
                    title,
                    style: AccountInformationStyles.sectionTitleStyle,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _AccountInformationRow extends StatelessWidget {
  const _AccountInformationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AccountInformationStyles.informationRowPadding,
      child: Row(
        children: <Widget>[
          _InformationIcon(icon: icon),
          const SizedBox(width: AccountInformationStyles.rowContentSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: AccountInformationStyles.informationLabelStyle,
                ),
                const SizedBox(
                  height: AccountInformationStyles.informationValueSpacing,
                ),
                Text(
                  value,
                  style: AccountInformationStyles.informationValueStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InformationIcon extends StatelessWidget {
  const _InformationIcon({
    required this.icon,
    this.color = AccountInformationStyles.primaryColor,
    this.backgroundColor =
        AccountInformationStyles.informationIconBackgroundColor,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AccountInformationStyles.informationIconContainerSize,
      height: AccountInformationStyles.informationIconContainerSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AccountInformationStyles.informationIconRadius,
      ),
      child: Icon(
        icon,
        size: AccountInformationStyles.informationIconSize,
        color: color,
      ),
    );
  }
}

class _InformationDivider extends StatelessWidget {
  const _InformationDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: AccountInformationStyles.dividerIndent,
      endIndent: AccountInformationStyles.dividerEndIndent,
      color: AccountInformationStyles.dividerColor,
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AccountInformationStyles.noticePadding,
      decoration: const BoxDecoration(
        color: AccountInformationStyles.noticeBackgroundColor,
        borderRadius: AccountInformationStyles.cardRadius,
        border: AccountInformationStyles.noticeBorder,
      ),
      child: Row(
        children: <Widget>[
          _InformationIcon(icon: icon),
          const SizedBox(width: AccountInformationStyles.rowContentSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AccountInformationStyles.noticeTitleStyle),
                const SizedBox(
                  height: AccountInformationStyles.noticeDescriptionSpacing,
                ),
                Text(
                  description,
                  style: AccountInformationStyles.noticeDescriptionStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBrailleDecoration extends StatelessWidget {
  const _HeaderBrailleDecoration();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: AccountInformationStyles.decorationOpacity,
      child: SizedBox(
        width: AccountInformationStyles.decorationWidth,
        child: Wrap(
          spacing: AccountInformationStyles.decorationDotSpacing,
          runSpacing: AccountInformationStyles.decorationDotSpacing,
          children: List<Widget>.generate(
            AccountInformationStyles.decorationDotCount,
            (int index) {
              return const DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: AccountInformationStyles.decorationDotSize,
                  height: AccountInformationStyles.decorationDotSize,
                ),
              );
            },
            growable: false,
          ),
        ),
      ),
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
