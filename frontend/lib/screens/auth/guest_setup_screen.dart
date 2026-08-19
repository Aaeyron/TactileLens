import 'package:flutter/material.dart';

import '../../styles/screens/auth/guest_setup_screen_styles.dart';
import '../../utils/session_manager.dart';
import '../main/main_screen.dart';

enum _GuestRole {
  student,
  educator,
}

class GuestSetupScreen extends StatefulWidget {
  const GuestSetupScreen({super.key});

  @override
  State<GuestSetupScreen> createState() {
    return _GuestSetupScreenState();
  }
}

class _GuestSetupScreenState
    extends State<GuestSetupScreen> {
  final TextEditingController _nicknameController =
      TextEditingController();

  _GuestRole _selectedRole = _GuestRole.student;
  bool _isSaving = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  String get _selectedRoleName {
    return switch (_selectedRole) {
      _GuestRole.student => GuestStyles.studentLabel,
      _GuestRole.educator => GuestStyles.educatorLabel,
    };
  }

  Future<void> _continueAsGuest() async {
    if (_isSaving) {
      return;
    }

    FocusScope.of(context).unfocus();

    final String nickname =
        _nicknameController.text.trim();

    if (nickname.isEmpty) {
      _showMessage(
        GuestStyles.nicknameRequiredMessage,
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await SessionManager.saveGuest(
        nickname: nickname,
        role: _selectedRoleName,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return const MainScreen();
          },
        ),
        (Route<dynamic> route) => false,
      );
    } catch (error, stackTrace) {
      debugPrint('Guest setup failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        GuestStyles.guestSetupErrorMessage,
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              GuestStyles.primaryDarkColor,
        ),
      );
  }

  void _selectRole(_GuestRole role) {
    if (_isSaving) {
      return;
    }

    setState(() {
      _selectedRole = role;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GuestStyles.backgroundColor,
      body: Stack(
        children: <Widget>[
          const _BackgroundDecorations(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: GuestStyles.pagePadding,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildBackButton(),
                  _buildIntroduction(),
                  const SizedBox(
                    height: GuestStyles.offlineTopSpacing,
                  ),
                  _buildOfflineNotice(),
                  const SizedBox(
                    height:
                        GuestStyles.sectionTopSpacing,
                  ),
                  _buildNicknameSection(),
                  const SizedBox(
                    height:
                        GuestStyles.sectionTopSpacing,
                  ),
                  _buildRoleSection(),
                  const SizedBox(
                    height:
                        GuestStyles.sectionTopSpacing,
                  ),
                  _buildContinueButton(),
                  const SizedBox(
                    height:
                        GuestStyles.sectionTopSpacing,
                  ),
                  const _BottomIllustration(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: GuestStyles.backButtonSize,
        height: GuestStyles.backButtonSize,
        child: IconButton(
          tooltip: GuestStyles.backTooltip,
          onPressed: _isSaving
              ? null
              : () {
                  Navigator.of(context).maybePop();
                },
          icon: const Icon(
            Icons.arrow_back_rounded,
            size: GuestStyles.backIconSize,
          ),
          color: GuestStyles.titleColor,
        ),
      ),
    );
  }

  Widget _buildIntroduction() {
    return Column(
      children: <Widget>[
        Center(
          child: Container(
            width: GuestStyles.logoContainerSize,
            height: GuestStyles.logoContainerSize,
            padding: GuestStyles.logoPadding,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              gradient: GuestStyles.logoGradient,
              borderRadius: GuestStyles.logoRadius,
              boxShadow: GuestStyles.logoShadow,
            ),
            child: Image.asset(
              GuestStyles.logoAsset,
              fit: BoxFit.contain,
              semanticLabel:
                  GuestStyles.logoSemanticLabel,
            ),
          ),
        ),
        const SizedBox(
          height: GuestStyles.titleTopSpacing,
        ),
        const Text(
          GuestStyles.title,
          textAlign: TextAlign.center,
          style: GuestStyles.titleStyle,
        ),
        const SizedBox(
          height: GuestStyles.descriptionTopSpacing,
        ),
        const Text(
          GuestStyles.description,
          textAlign: TextAlign.center,
          style: GuestStyles.descriptionStyle,
        ),
      ],
    );
  }

  Widget _buildOfflineNotice() {
    return Container(
      padding: GuestStyles.offlineNoticePadding,
      decoration:
          GuestStyles.offlineNoticeDecoration,
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.cloud_off_outlined,
            color: GuestStyles.primaryColor,
          ),
          SizedBox(
            width: GuestStyles.itemSpacing,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  GuestStyles.offlineTitle,
                  style:
                      GuestStyles.offlineTitleStyle,
                ),
                SizedBox(
                  height: GuestStyles.smallSpacing,
                ),
                Text(
                  GuestStyles.offlineDescription,
                  style: GuestStyles
                      .offlineDescriptionStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNicknameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionHeading(
          icon: Icons.person_outline_rounded,
          title: GuestStyles.nicknameLabel,
        ),
        const SizedBox(
          height: GuestStyles.itemSpacing,
        ),
        SizedBox(
          height: GuestStyles.inputHeight,
          child: TextField(
            controller: _nicknameController,
            enabled: !_isSaving,
            maxLength:
                GuestStyles.nicknameMaximumLength,
            textCapitalization:
                TextCapitalization.words,
            textInputAction: TextInputAction.done,
            style: GuestStyles.inputStyle,
            decoration:
                GuestStyles.nicknameInputDecoration,
            onSubmitted: (_) {
              _continueAsGuest();
            },
          ),
        ),
        const SizedBox(
          height: GuestStyles.smallSpacing,
        ),
        const Text(
          GuestStyles.nicknameHelper,
          style: GuestStyles.helperStyle,
        ),
      ],
    );
  }

  Widget _buildRoleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionHeading(
          icon: Icons.groups_2_outlined,
          title: GuestStyles.roleLabel,
        ),
        const SizedBox(
          height: GuestStyles.smallSpacing,
        ),
        const Text(
          GuestStyles.roleDescription,
          style: GuestStyles.sectionDescriptionStyle,
        ),
        const SizedBox(
          height: GuestStyles.itemSpacing,
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: _RoleOption(
                title: GuestStyles.studentLabel,
                description:
                    GuestStyles.studentDescription,
                icon: Icons.school_outlined,
                accentColor:
                    GuestStyles.primaryColor,
                accentBackgroundColor:
                    GuestStyles.primarySoftColor,
                isSelected:
                    _selectedRole ==
                    _GuestRole.student,
                onPressed: () {
                  _selectRole(_GuestRole.student);
                },
              ),
            ),
            const SizedBox(
              width: GuestStyles.roleCardGap,
            ),
            Expanded(
              child: _RoleOption(
                title: GuestStyles.educatorLabel,
                description:
                    GuestStyles.educatorDescription,
                icon: Icons.co_present_outlined,
                accentColor:
                    GuestStyles.educatorColor,
                accentBackgroundColor:
                    GuestStyles.educatorSoftColor,
                isSelected:
                    _selectedRole ==
                    _GuestRole.educator,
                onPressed: () {
                  _selectRole(_GuestRole.educator);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return Semantics(
      button: true,
      label: GuestStyles.continueLabel,
      child: Container(
        height: GuestStyles.buttonHeight,
        decoration:
            GuestStyles.continueButtonDecoration,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap:
                _isSaving ? null : _continueAsGuest,
            borderRadius: GuestStyles.buttonRadius,
            child: Padding(
              padding:
                  GuestStyles.continueButtonPadding,
              child: _isSaving
                  ? const Center(
                      child: SizedBox.square(
                        dimension: GuestStyles
                            .loadingIndicatorSize,
                        child:
                            CircularProgressIndicator(
                              strokeWidth: GuestStyles
                                  .loadingIndicatorStrokeWidth,
                              color:
                                  GuestStyles.whiteColor,
                            ),
                      ),
                    )
                  : const Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        Align(
                          alignment:
                              Alignment.centerLeft,
                          child: Icon(
                            Icons
                                .person_add_alt_1_outlined,
                            size: GuestStyles
                                .buttonIconSize,
                            color:
                                GuestStyles.whiteColor,
                          ),
                        ),
                        Text(
                          GuestStyles.continueLabel,
                          style:
                              GuestStyles.buttonTextStyle,
                        ),
                        Align(
                          alignment:
                              Alignment.centerRight,
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: GuestStyles
                                .buttonIconSize,
                            color:
                                GuestStyles.whiteColor,
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
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(
          icon,
          size: GuestStyles.sectionIconSize,
          color: GuestStyles.primaryColor,
        ),
        const SizedBox(
          width: GuestStyles.itemSpacing,
        ),
        Text(
          title,
          style: GuestStyles.sectionTitleStyle,
        ),
      ],
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.accentBackgroundColor,
    required this.isSelected,
    required this.onPressed,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final Color accentBackgroundColor;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: title,
      button: true,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: GuestStyles.roleCardRadius,
          child: AnimatedContainer(
            duration:
                GuestStyles.roleAnimationDuration,
            curve: Curves.easeOut,
            height: GuestStyles.roleCardHeight,
            padding: GuestStyles.roleCardPadding,
            decoration: BoxDecoration(
              color: isSelected
                  ? GuestStyles
                      .selectedRoleBackground
                  : GuestStyles.surfaceColor,
              borderRadius:
                  GuestStyles.roleCardRadius,
              border: Border.all(
                color: isSelected
                    ? GuestStyles.primaryColor
                    : GuestStyles.outlineColor,
                width: isSelected
                    ? GuestStyles
                        .selectedRoleBorderWidth
                    : GuestStyles.roleBorderWidth,
              ),
              boxShadow:
                  GuestStyles.roleCardShadow,
            ),
            child: Stack(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: GuestStyles
                          .roleIconContainerSize,
                      height: GuestStyles
                          .roleIconContainerSize,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? GuestStyles
                                .primarySoftColor
                            : accentBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size:
                            GuestStyles.roleIconSize,
                        color: isSelected
                            ? GuestStyles.primaryColor
                            : accentColor,
                      ),
                    ),
                    const SizedBox(
                      width: GuestStyles
                          .roleContentSpacing,
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: GuestStyles
                                .roleTitleStyle,
                          ),
                          const SizedBox(
                            height: GuestStyles
                                .roleDescriptionSpacing,
                          ),
                          Text(
                            description,
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: GuestStyles
                                .roleDescriptionStyle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: GuestStyles
                      .roleSelectionOffset,
                  right: GuestStyles
                      .roleSelectionOffset,
                  child: Container(
                    width: GuestStyles
                        .roleSelectionSize,
                    height: GuestStyles
                        .roleSelectionSize,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? GuestStyles.primaryColor
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? GuestStyles.primaryColor
                            : GuestStyles
                                .unselectedRoleCircleColor,
                        width: GuestStyles
                            .roleSelectionBorderWidth,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color:
                                GuestStyles.whiteColor,
                            size: GuestStyles
                                .roleCheckIconSize,
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackgroundDecorations
    extends StatelessWidget {
  const _BackgroundDecorations();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          Positioned(
            top: GuestStyles.topCircleTop,
            right: GuestStyles.topCircleRight,
            child: Container(
              width:
                  GuestStyles.decorativeCircleSize,
              height:
                  GuestStyles.decorativeCircleSize,
              decoration: const BoxDecoration(
                color: GuestStyles
                    .decorationLightColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Positioned(
            top: GuestStyles.topDotsTop,
            left: GuestStyles.topDotsLeft,
            child: _BrailleDots(),
          ),
          const Positioned(
            top: GuestStyles.rightDotsTop,
            right: GuestStyles.rightDotsRight,
            child: _BrailleDots(),
          ),
        ],
      ),
    );
  }
}

class _BrailleDots extends StatelessWidget {
  const _BrailleDots();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: GuestStyles.decorativeDotSize * 4,
      child: Wrap(
        spacing:
            GuestStyles.decorativeDotSpacing,
        runSpacing:
            GuestStyles.decorativeDotSpacing,
        children: List<Widget>.generate(
          GuestStyles.decorativeDotCount,
          (int index) {
            return const DecoratedBox(
              decoration: BoxDecoration(
                color:
                    GuestStyles.decorationColor,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension:
                    GuestStyles.decorativeDotSize,
              ),
            );
          },
          growable: false,
        ),
      ),
    );
  }
}

class _BottomIllustration extends StatelessWidget {
  const _BottomIllustration();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.menu_book_rounded,
        size: GuestStyles.bottomIllustrationSize,
        color: GuestStyles.decorationColor,
      ),
    );
  }
}