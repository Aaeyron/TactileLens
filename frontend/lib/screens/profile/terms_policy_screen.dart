import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../styles/screens/profile/terms_policy_screen_styles.dart';

class TermsPolicyScreen extends StatefulWidget {
  const TermsPolicyScreen({super.key});

  @override
  State<TermsPolicyScreen> createState() {
    return _TermsPolicyScreenState();
  }
}

class _TermsPolicyScreenState extends State<TermsPolicyScreen>
    with SingleTickerProviderStateMixin {
  static const int _termsTabIndex = 0;
  static const int _privacyTabIndex = 1;

  static const List<_PolicySectionData> _termsSections = <_PolicySectionData>[
    _PolicySectionData(
      icon: TermsPolicyScreenStyles.acceptanceIcon,
      title: 'Acceptance of Terms',
      body:
          'By using TactileLens, you agree to these terms and conditions. '
          'If you do not agree, please discontinue use of the application.',
    ),
    _PolicySectionData(
      icon: TermsPolicyScreenStyles.appUseIcon,
      title: 'Use of the Application',
      body:
          'TactileLens is intended for educational and accessibility '
          'purposes. You agree to use the application responsibly and '
          'in accordance with applicable laws.',
    ),
    _PolicySectionData(
      icon: TermsPolicyScreenStyles.responsibilityIcon,
      title: 'User Responsibilities',
      body:
          'You are responsible for the documents and learning materials '
          'you capture, upload, translate, organize, or share through '
          'TactileLens.',
    ),
    _PolicySectionData(
      icon: TermsPolicyScreenStyles.intellectualPropertyIcon,
      title: 'Intellectual Property',
      body:
          'The TactileLens application, interface, branding, and original '
          'materials are protected by applicable intellectual property '
          'and copyright laws.',
    ),
    _PolicySectionData(
      icon: TermsPolicyScreenStyles.accuracyIcon,
      title: 'Translation Accuracy',
      body:
          'AI-generated recognition and Braille output should be reviewed '
          'by a qualified educator before being used as a final accessible '
          'learning material.',
    ),
    _PolicySectionData(
      icon: TermsPolicyScreenStyles.liabilityIcon,
      title: 'Limitation of Liability',
      body:
          'TactileLens is provided as an educational support tool. The '
          'developers are not responsible for losses resulting from '
          'incorrect input, unreviewed output, or improper use.',
    ),
  ];

  static const List<_PolicySectionData> _privacySections = <_PolicySectionData>[
    _PolicySectionData(
      icon: TermsPolicyScreenStyles.collectionIcon,
      title: 'Information We Process',
      body:
          'TactileLens processes only the information required to provide '
          'account, scanning, accessibility, history, and material '
          'organization features.',
    ),
    _PolicySectionData(
      icon: TermsPolicyScreenStyles.dataUseIcon,
      title: 'How Information Is Used',
      body:
          'Information is used to operate the application, maintain your '
          'account, process learning documents, and provide accessible '
          'text and Braille output.',
    ),
    _PolicySectionData(
      icon: TermsPolicyScreenStyles.offlineIcon,
      title: 'Guest and Offline Data',
      body:
          'When using Guest Mode, supported scans, history, and materials '
          'are stored locally on the device and are not connected to a '
          'registered account.',
    ),
    _PolicySectionData(
      icon: TermsPolicyScreenStyles.dataProtectionIcon,
      title: 'Data Protection',
      body:
          'Reasonable technical safeguards are used to protect account '
          'information and stored learning content from unauthorized '
          'access, alteration, or disclosure.',
    ),
    _PolicySectionData(
      icon: TermsPolicyScreenStyles.userRightsIcon,
      title: 'Your Rights',
      body:
          'You may review, correct, or request deletion of personal '
          'information associated with your account, subject to applicable '
          'requirements.',
    ),
    _PolicySectionData(
      icon: TermsPolicyScreenStyles.updatesIcon,
      title: 'Policy Updates',
      body:
          'These policies may be updated as TactileLens evolves. Important '
          'changes should be communicated through the application or '
          'official project channels.',
    ),
  ];

  late final AnimationController _entranceController;
  late final Animation<double> _entranceOpacity;
  late final Animation<Offset> _entrancePosition;

  int _selectedTab = _termsTabIndex;

  bool get _showingTerms => _selectedTab == _termsTabIndex;

  List<_PolicySectionData> get _visibleSections {
    return _showingTerms ? _termsSections : _privacySections;
  }

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: TermsPolicyScreenStyles.entranceDuration,
    );

    final CurvedAnimation animation = CurvedAnimation(
      parent: _entranceController,
      curve: TermsPolicyScreenStyles.entranceCurve,
    );

    _entranceOpacity = animation;

    _entrancePosition = Tween<Offset>(
      begin: TermsPolicyScreenStyles.entranceBeginOffset,
      end: Offset.zero,
    ).animate(animation);

    Future<void>.delayed(TermsPolicyScreenStyles.entranceDelay, () {
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

  void _selectTab(int index) {
    if (_selectedTab == index) {
      return;
    }

    setState(() {
      _selectedTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: TermsPolicyScreenStyles.backgroundColor,
        body: FadeTransition(
          opacity: _entranceOpacity,
          child: SlideTransition(
            position: _entrancePosition,
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: <Widget>[
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverPadding(
                  padding: TermsPolicyScreenStyles.contentPadding,
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed(<Widget>[
                      const _PolicyIntroductionCard(),
                      const SizedBox(
                        height: TermsPolicyScreenStyles.sectionSpacing,
                      ),
                      _PolicyTabs(
                        selectedIndex: _selectedTab,
                        onSelected: _selectTab,
                      ),
                      const SizedBox(
                        height: TermsPolicyScreenStyles.cardSpacing,
                      ),
                      AnimatedSwitcher(
                        duration: TermsPolicyScreenStyles.contentSwitchDuration,
                        switchInCurve:
                            TermsPolicyScreenStyles.contentSwitchCurve,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              final Animation<Offset> position = Tween<Offset>(
                                begin: TermsPolicyScreenStyles
                                    .contentSwitchBeginOffset,
                                end: Offset.zero,
                              ).animate(animation);

                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: position,
                                  child: child,
                                ),
                              );
                            },
                        child: _PolicyContent(
                          key: ValueKey<int>(_selectedTab),
                          title: _showingTerms
                              ? TermsPolicyScreenStyles.termsContentTitle
                              : TermsPolicyScreenStyles.privacyContentTitle,
                          description: _showingTerms
                              ? TermsPolicyScreenStyles.termsContentDescription
                              : TermsPolicyScreenStyles
                                    .privacyContentDescription,
                          sections: _visibleSections,
                        ),
                      ),
                      const SizedBox(
                        height: TermsPolicyScreenStyles.cardSpacing,
                      ),
                      _PolicyNotice(isTerms: _showingTerms),
                      const SizedBox(
                        height: TermsPolicyScreenStyles.bottomSpacing,
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final double statusBarHeight = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        TermsPolicyScreenStyles.headerHorizontalPadding,
        statusBarHeight + TermsPolicyScreenStyles.headerTopPadding,
        TermsPolicyScreenStyles.headerHorizontalPadding,
        TermsPolicyScreenStyles.headerBottomPadding,
      ),
      decoration: const BoxDecoration(
        gradient: TermsPolicyScreenStyles.headerGradient,
        borderRadius: TermsPolicyScreenStyles.headerRadius,
      ),
      child: Stack(
        children: <Widget>[
          const Positioned(
            right: TermsPolicyScreenStyles.decorationRight,
            bottom: TermsPolicyScreenStyles.decorationBottom,
            child: _HeaderBrailleDecoration(),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    tooltip: TermsPolicyScreenStyles.backTooltip,
                    onPressed: () {
                      Navigator.of(context).maybePop();
                    },
                    style: TermsPolicyScreenStyles.backButtonStyle,
                    icon: const Icon(
                      TermsPolicyScreenStyles.backIcon,
                      size: TermsPolicyScreenStyles.backIconSize,
                    ),
                  ),
                  const SizedBox(
                    width: TermsPolicyScreenStyles.headerBackSpacing,
                  ),
                  const Expanded(
                    child: Text(
                      TermsPolicyScreenStyles.screenTitle,
                      style: TermsPolicyScreenStyles.headerTitleStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TermsPolicyScreenStyles.headerTextSpacing),
              const Padding(
                padding: TermsPolicyScreenStyles.headerDescriptionPadding,
                child: SizedBox(
                  width: TermsPolicyScreenStyles.headerDescriptionWidth,
                  child: Text(
                    TermsPolicyScreenStyles.screenDescription,
                    style: TermsPolicyScreenStyles.headerDescriptionStyle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PolicyIntroductionCard extends StatelessWidget {
  const _PolicyIntroductionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: TermsPolicyScreenStyles.introductionPadding,
      decoration: const BoxDecoration(
        color: TermsPolicyScreenStyles.surfaceColor,
        borderRadius: TermsPolicyScreenStyles.cardRadius,
        border: TermsPolicyScreenStyles.cardBorder,
        boxShadow: TermsPolicyScreenStyles.cardShadow,
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _PolicyIcon(
            icon: TermsPolicyScreenStyles.heroIcon,
            highlighted: true,
          ),
          SizedBox(width: TermsPolicyScreenStyles.introductionContentSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  TermsPolicyScreenStyles.introductionTitle,
                  style: TermsPolicyScreenStyles.introductionTitleStyle,
                ),
                SizedBox(
                  height:
                      TermsPolicyScreenStyles.introductionDescriptionSpacing,
                ),
                Text(
                  TermsPolicyScreenStyles.introductionDescription,
                  style: TermsPolicyScreenStyles.bodyStyle,
                ),
                SizedBox(height: TermsPolicyScreenStyles.effectiveDateSpacing),
                Text(
                  TermsPolicyScreenStyles.effectiveDate,
                  style: TermsPolicyScreenStyles.effectiveDateStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyTabs extends StatelessWidget {
  const _PolicyTabs({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: TermsPolicyScreenStyles.tabContainerHeight,
      padding: TermsPolicyScreenStyles.tabContainerPadding,
      decoration: const BoxDecoration(
        color: TermsPolicyScreenStyles.surfaceColor,
        borderRadius: TermsPolicyScreenStyles.tabContainerRadius,
        border: TermsPolicyScreenStyles.cardBorder,
        boxShadow: TermsPolicyScreenStyles.tabShadow,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _PolicyTab(
              icon: TermsPolicyScreenStyles.termsIcon,
              label: TermsPolicyScreenStyles.termsTabLabel,
              accessibilityLabel:
                  TermsPolicyScreenStyles.termsTabAccessibilityLabel,
              selected: selectedIndex == _TermsPolicyScreenState._termsTabIndex,
              onPressed: () {
                onSelected(_TermsPolicyScreenState._termsTabIndex);
              },
            ),
          ),
          const SizedBox(width: TermsPolicyScreenStyles.tabSpacing),
          Expanded(
            child: _PolicyTab(
              icon: TermsPolicyScreenStyles.privacyIcon,
              label: TermsPolicyScreenStyles.privacyTabLabel,
              accessibilityLabel:
                  TermsPolicyScreenStyles.privacyTabAccessibilityLabel,
              selected:
                  selectedIndex == _TermsPolicyScreenState._privacyTabIndex,
              onPressed: () {
                onSelected(_TermsPolicyScreenState._privacyTabIndex);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyTab extends StatelessWidget {
  const _PolicyTab({
    required this.icon,
    required this.label,
    required this.accessibilityLabel,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String accessibilityLabel;
  final bool selected;
  final VoidCallback onPressed;

  void _handlePressed() {
    HapticFeedback.selectionClick();
    onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: accessibilityLabel,
      hint: selected
          ? TermsPolicyScreenStyles.selectedTabHint
          : TermsPolicyScreenStyles.unselectedTabHint,
      child: ExcludeSemantics(
        child: AnimatedScale(
          scale: selected
              ? TermsPolicyScreenStyles.selectedTabScale
              : TermsPolicyScreenStyles.unselectedTabScale,
          duration: TermsPolicyScreenStyles.tabAnimationDuration,
          curve: TermsPolicyScreenStyles.tabAnimationCurve,
          child: Material(
            color: Colors.transparent,
            borderRadius: TermsPolicyScreenStyles.tabRadius,
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: BoxDecoration(
                gradient: selected
                    ? TermsPolicyScreenStyles.selectedTabGradient
                    : null,
                color: selected
                    ? null
                    : TermsPolicyScreenStyles.unselectedTabBackgroundColor,
                borderRadius: TermsPolicyScreenStyles.tabRadius,
                border: selected
                    ? null
                    : Border.all(
                        color: TermsPolicyScreenStyles.unselectedTabBorderColor,
                      ),
                boxShadow: selected
                    ? TermsPolicyScreenStyles.selectedTabShadow
                    : null,
              ),
              child: InkWell(
                onTap: selected ? null : _handlePressed,
                borderRadius: TermsPolicyScreenStyles.tabRadius,
                splashColor: TermsPolicyScreenStyles.tabSplashColor,
                highlightColor: TermsPolicyScreenStyles.tabHighlightColor,
                child: Padding(
                  padding: TermsPolicyScreenStyles.tabContentPadding,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      AnimatedContainer(
                        duration: TermsPolicyScreenStyles.tabAnimationDuration,
                        curve: TermsPolicyScreenStyles.tabAnimationCurve,
                        width: TermsPolicyScreenStyles.tabIconContainerSize,
                        height: TermsPolicyScreenStyles.tabIconContainerSize,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? TermsPolicyScreenStyles
                                    .selectedTabIconBackgroundColor
                              : TermsPolicyScreenStyles
                                    .unselectedTabIconBackgroundColor,
                          borderRadius:
                              TermsPolicyScreenStyles.tabIconContainerRadius,
                        ),
                        child: Icon(
                          icon,
                          size: TermsPolicyScreenStyles.tabIconSize,
                          color: selected
                              ? TermsPolicyScreenStyles.surfaceColor
                              : TermsPolicyScreenStyles.primaryColor,
                        ),
                      ),
                      const SizedBox(
                        width: TermsPolicyScreenStyles.tabIconSpacing,
                      ),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: selected
                              ? TermsPolicyScreenStyles.selectedTabStyle
                              : TermsPolicyScreenStyles.unselectedTabStyle,
                        ),
                      ),
                      AnimatedSize(
                        duration: TermsPolicyScreenStyles.tabAnimationDuration,
                        curve: TermsPolicyScreenStyles.tabAnimationCurve,
                        child: selected
                            ? const Padding(
                                padding: EdgeInsets.only(
                                  left: TermsPolicyScreenStyles
                                      .selectedCheckSpacing,
                                ),
                                child: Icon(
                                  TermsPolicyScreenStyles.selectedTabIcon,
                                  size: TermsPolicyScreenStyles
                                      .selectedCheckIconSize,
                                  color: TermsPolicyScreenStyles.surfaceColor,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PolicyContent extends StatelessWidget {
  const _PolicyContent({
    super.key,
    required this.title,
    required this.description,
    required this.sections,
  });

  final String title;
  final String description;
  final List<_PolicySectionData> sections;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: TermsPolicyScreenStyles.sectionTitleStyle),
        const SizedBox(
          height: TermsPolicyScreenStyles.sectionDescriptionSpacing,
        ),
        Text(
          description,
          style: TermsPolicyScreenStyles.sectionDescriptionStyle,
        ),
        const SizedBox(height: TermsPolicyScreenStyles.policyListSpacing),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: TermsPolicyScreenStyles.surfaceColor,
            borderRadius: TermsPolicyScreenStyles.cardRadius,
            border: TermsPolicyScreenStyles.cardBorder,
            boxShadow: TermsPolicyScreenStyles.cardShadow,
          ),
          child: Column(
            children: List<Widget>.generate(sections.length, (int index) {
              return _PolicyItem(
                number: index + 1,
                section: sections[index],
                showDivider: index != sections.length - 1,
              );
            }, growable: false),
          ),
        ),
      ],
    );
  }
}

class _PolicyItem extends StatelessWidget {
  const _PolicyItem({
    required this.number,
    required this.section,
    required this.showDivider,
  });

  final int number;
  final _PolicySectionData section;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: TermsPolicyScreenStyles.policyItemPadding,
      decoration: showDivider
          ? const BoxDecoration(
              border: TermsPolicyScreenStyles.policyDividerBorder,
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              _PolicyIcon(icon: section.icon),
              Positioned(
                right: TermsPolicyScreenStyles.numberBadgeRight,
                top: TermsPolicyScreenStyles.numberBadgeTop,
                child: Container(
                  width: TermsPolicyScreenStyles.numberBadgeSize,
                  height: TermsPolicyScreenStyles.numberBadgeSize,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: TermsPolicyScreenStyles.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$number',
                    style: TermsPolicyScreenStyles.numberBadgeTextStyle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: TermsPolicyScreenStyles.policyContentSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  section.title,
                  style: TermsPolicyScreenStyles.policyTitleStyle,
                ),
                const SizedBox(
                  height: TermsPolicyScreenStyles.policyBodySpacing,
                ),
                Text(
                  section.body,
                  style: TermsPolicyScreenStyles.policyBodyStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyNotice extends StatelessWidget {
  const _PolicyNotice({required this.isTerms});

  final bool isTerms;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: TermsPolicyScreenStyles.noticePadding,
      decoration: BoxDecoration(
        color: isTerms
            ? TermsPolicyScreenStyles.noticeBackgroundColor
            : TermsPolicyScreenStyles.privacyNoticeBackgroundColor,
        borderRadius: TermsPolicyScreenStyles.cardRadius,
        border: Border.all(
          color: isTerms
              ? TermsPolicyScreenStyles.noticeBorderColor
              : TermsPolicyScreenStyles.privacyNoticeBorderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _PolicyIcon(
            icon: isTerms
                ? TermsPolicyScreenStyles.informationIcon
                : TermsPolicyScreenStyles.dataProtectionIcon,
          ),
          const SizedBox(width: TermsPolicyScreenStyles.noticeContentSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isTerms
                      ? TermsPolicyScreenStyles.termsNoticeTitle
                      : TermsPolicyScreenStyles.privacyNoticeTitle,
                  style: TermsPolicyScreenStyles.noticeTitleStyle,
                ),
                const SizedBox(
                  height: TermsPolicyScreenStyles.noticeDescriptionSpacing,
                ),
                Text(
                  isTerms
                      ? TermsPolicyScreenStyles.termsNoticeDescription
                      : TermsPolicyScreenStyles.privacyNoticeDescription,
                  style: TermsPolicyScreenStyles.noticeBodyStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyIcon extends StatelessWidget {
  const _PolicyIcon({required this.icon, this.highlighted = false});

  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: TermsPolicyScreenStyles.policyIconContainerSize,
      height: TermsPolicyScreenStyles.policyIconContainerSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: highlighted
            ? TermsPolicyScreenStyles.iconHighlightGradient
            : null,
        color: highlighted ? null : TermsPolicyScreenStyles.primarySoftColor,
        borderRadius: TermsPolicyScreenStyles.policyIconRadius,
      ),
      child: Icon(
        icon,
        size: TermsPolicyScreenStyles.policyIconSize,
        color: highlighted
            ? TermsPolicyScreenStyles.surfaceColor
            : TermsPolicyScreenStyles.primaryColor,
      ),
    );
  }
}

class _HeaderBrailleDecoration extends StatelessWidget {
  const _HeaderBrailleDecoration();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: TermsPolicyScreenStyles.decorationOpacity,
      child: SizedBox(
        width: TermsPolicyScreenStyles.decorationWidth,
        child: Wrap(
          spacing: TermsPolicyScreenStyles.decorationDotSpacing,
          runSpacing: TermsPolicyScreenStyles.decorationDotSpacing,
          children: List<Widget>.generate(
            TermsPolicyScreenStyles.decorationDotCount,
            (int index) {
              return const DecoratedBox(
                decoration: BoxDecoration(
                  color: TermsPolicyScreenStyles.surfaceColor,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: TermsPolicyScreenStyles.decorationDotSize,
                  height: TermsPolicyScreenStyles.decorationDotSize,
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

class _PolicySectionData {
  const _PolicySectionData({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
