import 'package:flutter/material.dart';

import '../../styles/screens/profile/terms_policy_screen_styles.dart';
import '../../widgets/app_header.dart';

class TermsPolicyScreen extends StatefulWidget {
  const TermsPolicyScreen({super.key});

  @override
  State<TermsPolicyScreen> createState() => _TermsPolicyScreenState();
}

class _TermsPolicyScreenState extends State<TermsPolicyScreen> {
  static const int _termsTabIndex = 0;
  static const int _privacyTabIndex = 1;

  static const List<_PolicySectionData> _termsSections = <_PolicySectionData>[
    _PolicySectionData(
      icon: TermsPolicyScreenStyles.acceptanceIcon,
      title: '1. Acceptance of Terms',
      body:
          'By using TactileLens, you agree to these terms and conditions. If you do not agree, please do not use the app.',
    ),
    _PolicySectionData(
      icon: TermsPolicyScreenStyles.appUseIcon,
      title: '2. Use of the App',
      body:
          'TactileLens is intended for educational and accessibility purposes only. You agree to use the app responsibly and lawfully.',
    ),
    _PolicySectionData(
      icon: TermsPolicyScreenStyles.responsibilityIcon,
      title: '3. User Responsibilities',
      body:
          'You are responsible for the content you scan, upload, or translate. Do not use the app for harmful or unlawful activities.',
    ),
    _PolicySectionData(
      icon: TermsPolicyScreenStyles.intellectualPropertyIcon,
      title: '4. Intellectual Property',
      body:
          'All content, features, and materials within TactileLens are protected by copyright and other intellectual property laws.',
    ),
    _PolicySectionData(
      icon: TermsPolicyScreenStyles.liabilityIcon,
      title: '5. Limitation of Liability',
      body:
          'TactileLens is provided “as is” without warranties. We are not liable for damages arising from your use of the app.',
    ),
  ];

  static const List<_PolicySectionData> _privacySections =
      <_PolicySectionData>[
    _PolicySectionData(
      icon: TermsPolicyScreenStyles.collectionIcon,
      title: '1. Information We Collect',
      body:
          'TactileLens only processes the information needed to provide its accessibility and synchronization features.',
    ),
    _PolicySectionData(
      icon: TermsPolicyScreenStyles.dataUseIcon,
      title: '2. How Information Is Used',
      body:
          'Your information is used to operate the app, maintain your account, and improve your learning experience.',
    ),
    _PolicySectionData(
      icon: TermsPolicyScreenStyles.dataProtectionIcon,
      title: '3. Data Protection',
      body:
          'We apply appropriate safeguards to protect your information from unauthorized access, alteration, or disclosure.',
    ),
    _PolicySectionData(
      icon: TermsPolicyScreenStyles.userRightsIcon,
      title: '4. Your Rights',
      body:
          'You may review, correct, or request deletion of your personal information, subject to applicable requirements.',
    ),
    _PolicySectionData(
      icon: TermsPolicyScreenStyles.updatesIcon,
      title: '5. Policy Updates',
      body:
          'This policy may be updated as TactileLens evolves. Important changes will be communicated through the app.',
    ),
  ];

  int _selectedTab = _termsTabIndex;
  bool _hasAgreed = false;

  bool get _showingTerms => _selectedTab == _termsTabIndex;

  List<_PolicySectionData> get _visibleSections =>
      _showingTerms ? _termsSections : _privacySections;

  void _selectTab(int index) {
    if (_selectedTab == index) return;
    setState(() => _selectedTab = index);
  }

  void _setAgreement(bool? value) {
    setState(() => _hasAgreed = value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TermsPolicyScreenStyles.backgroundColor,
    appBar: PreferredSize(
  preferredSize: const Size.fromHeight(100),
  child: Stack(
    children: <Widget>[
      const AppHeader(),
      SafeArea(
        child: SizedBox(
          height: 76,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back),
                  color: TermsPolicyScreenStyles.textPrimaryColor,
                ),
              ),
              const Text(
                'Terms & Policy',
                style: TermsPolicyScreenStyles.appBarTitleStyle,
              ),
            ],
          ),
        ),
      ),
    ],
  ),
),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: TermsPolicyScreenStyles.screenPadding,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: TermsPolicyScreenStyles.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const _HeroSection(),
                  const SizedBox(height: TermsPolicyScreenStyles.space20),
                  _PolicyTabs(
                    selectedIndex: _selectedTab,
                    onSelected: _selectTab,
                  ),
                  const SizedBox(height: TermsPolicyScreenStyles.space16),
                  _PolicyCard(sections: _visibleSections),
                  const SizedBox(height: TermsPolicyScreenStyles.space14),
                  _ImportantNote(isTerms: _showingTerms),
                  if (_showingTerms) ...<Widget>[
                    const SizedBox(height: TermsPolicyScreenStyles.space12),
                    _AgreementRow(
                      value: _hasAgreed,
                      onChanged: _setAgreement,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact =
            constraints.maxWidth < TermsPolicyScreenStyles.compactBreakpoint;
        return Container(
          padding: compact
              ? TermsPolicyScreenStyles.compactHeroPadding
              : TermsPolicyScreenStyles.heroPadding,
          decoration: const BoxDecoration(
            gradient: TermsPolicyScreenStyles.heroGradient,
            borderRadius: TermsPolicyScreenStyles.cardRadius,
            border: TermsPolicyScreenStyles.cardBorder,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: TermsPolicyScreenStyles.heroIconBoxSize,
                height: TermsPolicyScreenStyles.heroIconBoxSize,
                decoration: const BoxDecoration(
                  color: TermsPolicyScreenStyles.primaryColor,
                  borderRadius: TermsPolicyScreenStyles.heroIconRadius,
                  boxShadow: TermsPolicyScreenStyles.cardShadow,
                ),
                child: const Icon(
                  TermsPolicyScreenStyles.heroIcon,
                  color: TermsPolicyScreenStyles.cardColor,
                  size: TermsPolicyScreenStyles.heroIconSize,
                ),
              ),
              const SizedBox(width: TermsPolicyScreenStyles.space18),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Terms & Policy',
                      style: TermsPolicyScreenStyles.heroTitleStyle,
                    ),
                    SizedBox(height: TermsPolicyScreenStyles.space8),
                    Text(
                      'Your trust and privacy are important to us.',
                      style: TermsPolicyScreenStyles.heroSubtitleStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PolicyTabs extends StatelessWidget {
  const _PolicyTabs({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: TermsPolicyScreenStyles.segmentHeight,
      padding: TermsPolicyScreenStyles.segmentOuterPadding,
      decoration: const BoxDecoration(
        color: TermsPolicyScreenStyles.cardColor,
        borderRadius: TermsPolicyScreenStyles.segmentRadius,
        border: TermsPolicyScreenStyles.segmentBorder,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _PolicyTab(
              label: 'Terms of Use',
              selected: selectedIndex == _TermsPolicyScreenState._termsTabIndex,
              onTap: () => onSelected(_TermsPolicyScreenState._termsTabIndex),
            ),
          ),
          Expanded(
            child: _PolicyTab(
              label: 'Privacy Policy',
              selected:
                  selectedIndex == _TermsPolicyScreenState._privacyTabIndex,
              onTap: () => onSelected(_TermsPolicyScreenState._privacyTabIndex),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyTab extends StatelessWidget {
  const _PolicyTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: TermsPolicyScreenStyles.segmentRadius,
        child: AnimatedContainer(
          duration: TermsPolicyScreenStyles.segmentAnimationDuration,
          curve: TermsPolicyScreenStyles.segmentAnimationCurve,
          padding: TermsPolicyScreenStyles.segmentPadding,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient:
                selected ? TermsPolicyScreenStyles.selectedSegmentGradient : null,
            color: selected
                ? null
                : TermsPolicyScreenStyles.transparentColor,
            borderRadius: TermsPolicyScreenStyles.segmentRadius,
            boxShadow: selected
                ? TermsPolicyScreenStyles.selectedSegmentShadow
                : null,
          ),
          child: Text(
            label,
            style: selected
                ? TermsPolicyScreenStyles.selectedSegmentStyle
                : TermsPolicyScreenStyles.unselectedSegmentStyle,
          ),
        ),
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({required this.sections});

  final List<_PolicySectionData> sections;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact =
            constraints.maxWidth < TermsPolicyScreenStyles.compactBreakpoint;
        return Container(
          padding: compact
              ? TermsPolicyScreenStyles.compactPolicyCardPadding
              : TermsPolicyScreenStyles.policyCardPadding,
          decoration: const BoxDecoration(
            color: TermsPolicyScreenStyles.cardColor,
            borderRadius: TermsPolicyScreenStyles.cardRadius,
            border: TermsPolicyScreenStyles.cardBorder,
            boxShadow: TermsPolicyScreenStyles.cardShadow,
          ),
          child: Column(
            children: List<Widget>.generate(
              sections.length,
              (int index) => _PolicyItem(
                section: sections[index],
                compact: compact,
                showDivider: index != sections.length - 1,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PolicyItem extends StatelessWidget {
  const _PolicyItem({
    required this.section,
    required this.compact,
    required this.showDivider,
  });

  final _PolicySectionData section;
  final bool compact;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: TermsPolicyScreenStyles.policyItemPadding,
      decoration: showDivider
          ? const BoxDecoration(
              border: TermsPolicyScreenStyles.itemDividerBorder,
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: compact
                ? TermsPolicyScreenStyles.compactPolicyIconBoxSize
                : TermsPolicyScreenStyles.policyIconBoxSize,
            height: compact
                ? TermsPolicyScreenStyles.compactPolicyIconBoxSize
                : TermsPolicyScreenStyles.policyIconBoxSize,
            decoration: const BoxDecoration(
              color: TermsPolicyScreenStyles.primarySoftColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              section.icon,
              color: TermsPolicyScreenStyles.primaryColor,
              size: TermsPolicyScreenStyles.policyIconSize,
            ),
          ),
          const SizedBox(width: TermsPolicyScreenStyles.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  section.title,
                  style: TermsPolicyScreenStyles.policyTitleStyle,
                ),
                const SizedBox(height: TermsPolicyScreenStyles.space8),
                Text(
                  section.body,
                  maxLines: TermsPolicyScreenStyles.policyBodyMaxLines,
                  overflow: TextOverflow.visible,
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

class _ImportantNote extends StatelessWidget {
  const _ImportantNote({required this.isTerms});

  final bool isTerms;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: TermsPolicyScreenStyles.notePadding,
      decoration: const BoxDecoration(
        gradient: TermsPolicyScreenStyles.heroGradient,
        borderRadius: TermsPolicyScreenStyles.cardRadius,
        border: TermsPolicyScreenStyles.cardBorder,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            TermsPolicyScreenStyles.informationIcon,
            color: TermsPolicyScreenStyles.primaryColor,
            size: TermsPolicyScreenStyles.noteIconSize,
          ),
          const SizedBox(width: TermsPolicyScreenStyles.space14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isTerms ? 'Important Note' : 'Your Privacy Matters',
                  style: TermsPolicyScreenStyles.noteTitleStyle,
                ),
                const SizedBox(height: TermsPolicyScreenStyles.space6),
                Text(
                  isTerms
                      ? 'These terms may be updated from time to time. Continued use of the app constitutes acceptance of the updated terms.'
                      : 'We are committed to protecting your privacy and providing a secure, inclusive learning experience.',
                  style: TermsPolicyScreenStyles.noteBodyStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgreementRow extends StatelessWidget {
  const _AgreementRow({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: TermsPolicyScreenStyles.cardRadius,
      child: Padding(
        padding: TermsPolicyScreenStyles.checkboxPadding,
        child: Row(
          children: <Widget>[
            SizedBox(
              width: TermsPolicyScreenStyles.checkboxSize,
              height: TermsPolicyScreenStyles.checkboxSize,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: TermsPolicyScreenStyles.primaryColor,
                side: const BorderSide(
                  color: TermsPolicyScreenStyles.primaryColor,
                  width: TermsPolicyScreenStyles.cardBorderWidth,
                ),
              ),
            ),
            const SizedBox(width: TermsPolicyScreenStyles.space12),
            const Expanded(
              child: Text(
                'I have read and agree to the Terms of Use.',
                style: TermsPolicyScreenStyles.agreementStyle,
              ),
            ),
          ],
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
