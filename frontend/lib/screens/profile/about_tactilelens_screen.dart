import 'package:flutter/material.dart';

import '../../styles/screens/profile/about_tactilelens_screen_styles.dart';

class AboutTactileLensScreen extends StatelessWidget {
  const AboutTactileLensScreen({super.key});

  static const List<_FeatureData> _features = <_FeatureData>[
    _FeatureData(
      icon: AboutTactileLensScreenStyles.scanIcon,
      title: 'Smart Scan',
      description: 'Capture or upload text and math content instantly.',
    ),
    _FeatureData(
      icon: AboutTactileLensScreenStyles.aiIcon,
      title: 'AI Assisted',
      description: 'Accurate translation to UEB and Nemeth Braille.',
    ),
    _FeatureData(
      icon: AboutTactileLensScreenStyles.offlineIcon,
      title: 'Offline First',
      description: 'Works fully offline with local storage and full features.',
    ),
    _FeatureData(
      icon: AboutTactileLensScreenStyles.organizedIcon,
      title: 'Organized',
      description: 'Save, categorize, and review your materials effortlessly.',
    ),
    _FeatureData(
      icon: AboutTactileLensScreenStyles.privacyIcon,
      title: 'Secure & Private',
      description: 'Your data stays on your device. We do not collect data.',
    ),
    _FeatureData(
      icon: AboutTactileLensScreenStyles.educatorIcon,
      title: 'For Educators',
      description: 'Designed for SPED teachers and their amazing learners.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AboutTactileLensScreenStyles.backgroundColor,
      appBar: AppBar(
        elevation: AboutTactileLensScreenStyles.appBarElevation,
        scrolledUnderElevation:
            AboutTactileLensScreenStyles.appBarScrolledUnderElevation,
        backgroundColor: AboutTactileLensScreenStyles.cardColor,
        foregroundColor: AboutTactileLensScreenStyles.textPrimaryColor,
        centerTitle: true,
        title: const Text(
          'About TactileLens',
          style: AboutTactileLensScreenStyles.appBarTitleStyle,
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: AboutTactileLensScreenStyles.screenPadding,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AboutTactileLensScreenStyles.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const _HeroSection(),
                  const SizedBox(height: AboutTactileLensScreenStyles.space16),
                  const _InformationCard(
                    icon: AboutTactileLensScreenStyles.missionIcon,
                    title: 'Our Mission',
                    body:
                        'Empower SPED educators with accurate and accessible tools to translate text and math into UEB and Nemeth Braille—making learning truly inclusive.',
                  ),
                  const SizedBox(height: AboutTactileLensScreenStyles.space12),
                  const _InformationCard(
                    icon: AboutTactileLensScreenStyles.overviewIcon,
                    title: 'What is TactileLens?',
                    body:
                        'TactileLens is an AI-assisted translator that converts printed text and math expressions into UEB and Nemeth Braille. It works offline, values privacy, and is built for educators, by educators.',
                  ),
                  const SizedBox(height: AboutTactileLensScreenStyles.space20),
                  const Text(
                    'Key Features',
                    style: AboutTactileLensScreenStyles.sectionTitleStyle,
                  ),
                  const SizedBox(height: AboutTactileLensScreenStyles.space12),
                  const _FeatureGrid(features: _features),
                  const SizedBox(height: AboutTactileLensScreenStyles.space24),
                  const Text(
                    'Project Information',
                    style: AboutTactileLensScreenStyles.sectionTitleStyle,
                  ),
                  const SizedBox(height: AboutTactileLensScreenStyles.space10),
                  const _ProjectInformationCard(),
                  const SizedBox(height: AboutTactileLensScreenStyles.space12),
                  const _AboutProjectCard(),
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
    return Container(
      padding: AboutTactileLensScreenStyles.heroPadding,
      decoration: const BoxDecoration(
        gradient: AboutTactileLensScreenStyles.heroGradient,
        borderRadius: AboutTactileLensScreenStyles.cardRadius,
        border: AboutTactileLensScreenStyles.cardBorder,
      ),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: AboutTactileLensScreenStyles.heroLogoBoxSize,
                height: AboutTactileLensScreenStyles.heroLogoBoxSize,
                decoration: const BoxDecoration(
                  color: AboutTactileLensScreenStyles.primaryColor,
                  borderRadius: AboutTactileLensScreenStyles.iconRadius,
                  boxShadow: AboutTactileLensScreenStyles.cardShadow,
                ),
                child: const Icon(
                  AboutTactileLensScreenStyles.appIcon,
                  color: AboutTactileLensScreenStyles.cardColor,
                  size: AboutTactileLensScreenStyles.heroLogoIconSize,
                ),
              ),
              const SizedBox(width: AboutTactileLensScreenStyles.space18),
              const Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'TactileLens',
                      style: AboutTactileLensScreenStyles.heroTitleStyle,
                    ),
                    SizedBox(height: AboutTactileLensScreenStyles.space6),
                    Text(
                      'See. Translate. Empower.',
                      style: AboutTactileLensScreenStyles.heroTaglineStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AboutTactileLensScreenStyles.space20),
          Container(
            padding: AboutTactileLensScreenStyles.badgePadding,
            decoration: const BoxDecoration(
              color: AboutTactileLensScreenStyles.primarySoftColor,
              borderRadius: AboutTactileLensScreenStyles.badgeRadius,
            ),
            child: const Text(
              'Version 1.0.0  •  Offline First',
              style: AboutTactileLensScreenStyles.badgeTextStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AboutTactileLensScreenStyles.informationCardPadding,
      decoration: const BoxDecoration(
        color: AboutTactileLensScreenStyles.cardColor,
        borderRadius: AboutTactileLensScreenStyles.cardRadius,
        border: AboutTactileLensScreenStyles.cardBorder,
        boxShadow: AboutTactileLensScreenStyles.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: AboutTactileLensScreenStyles.roundIconPadding,
            decoration: const BoxDecoration(
              color: AboutTactileLensScreenStyles.primarySoftColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AboutTactileLensScreenStyles.primaryAccentColor,
              size: AboutTactileLensScreenStyles.informationIconSize,
            ),
          ),
          const SizedBox(width: AboutTactileLensScreenStyles.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AboutTactileLensScreenStyles.cardTitleStyle),
                const SizedBox(height: AboutTactileLensScreenStyles.space8),
                Text(body, style: AboutTactileLensScreenStyles.bodyStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.features});

  final List<_FeatureData> features;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact =
            constraints.maxWidth < AboutTactileLensScreenStyles.compactBreakpoint;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: features.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: compact
                ? AboutTactileLensScreenStyles.compactGridColumns
                : AboutTactileLensScreenStyles.regularGridColumns,
            crossAxisSpacing: AboutTactileLensScreenStyles.gridSpacing,
            mainAxisSpacing: AboutTactileLensScreenStyles.gridSpacing,
            childAspectRatio: compact
                ? AboutTactileLensScreenStyles.compactFeatureGridAspectRatio
                : AboutTactileLensScreenStyles.featureGridAspectRatio,
          ),
          itemBuilder: (BuildContext context, int index) {
            return _FeatureCard(feature: features[index]);
          },
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final _FeatureData feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AboutTactileLensScreenStyles.featureCardPadding,
      decoration: const BoxDecoration(
        color: AboutTactileLensScreenStyles.primaryFaintColor,
        borderRadius: AboutTactileLensScreenStyles.featureRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: AboutTactileLensScreenStyles.featureIconPadding,
            decoration: const BoxDecoration(
              color: AboutTactileLensScreenStyles.primaryAccentColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              feature.icon,
              color: AboutTactileLensScreenStyles.cardColor,
              size: AboutTactileLensScreenStyles.featureIconSize,
            ),
          ),
          const SizedBox(height: AboutTactileLensScreenStyles.space10),
          Text(
            feature.title,
            textAlign: TextAlign.center,
            style: AboutTactileLensScreenStyles.featureTitleStyle,
          ),
          const SizedBox(height: AboutTactileLensScreenStyles.space6),
          Text(
            feature.description,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: AboutTactileLensScreenStyles.featureBodyStyle,
          ),
        ],
      ),
    );
  }
}

class _ProjectInformationCard extends StatelessWidget {
  const _ProjectInformationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AboutTactileLensScreenStyles.projectCardPadding,
      decoration: const BoxDecoration(
        color: AboutTactileLensScreenStyles.cardColor,
        borderRadius: AboutTactileLensScreenStyles.cardRadius,
        border: AboutTactileLensScreenStyles.cardBorder,
        boxShadow: AboutTactileLensScreenStyles.cardShadow,
      ),
      child: const Column(
        children: <Widget>[
          _ProjectRow(
            icon: AboutTactileLensScreenStyles.projectTypeIcon,
            label: 'Project Type',
            value: 'Capstone Project',
          ),
          _ProjectRow(
            icon: AboutTactileLensScreenStyles.institutionIcon,
            label: 'Institution',
            value: 'Holy Cross of Davao College',
          ),
          _ProjectRow(
            icon: AboutTactileLensScreenStyles.courseIcon,
            label: 'Course',
            value: 'BS Information Technology',
          ),
          _ProjectRow(
            icon: AboutTactileLensScreenStyles.yearIcon,
            label: 'Year',
            value: 'AY 2025-2026',
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AboutTactileLensScreenStyles.projectRowPadding,
      decoration: showDivider
          ? const BoxDecoration(
              border: AboutTactileLensScreenStyles.projectDividerBorder,
            )
          : null,
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            color: AboutTactileLensScreenStyles.primaryDarkColor,
            size: AboutTactileLensScreenStyles.projectIconSize,
          ),
          const SizedBox(width: AboutTactileLensScreenStyles.space12),
          SizedBox(
            width: AboutTactileLensScreenStyles.projectLabelColumnWidth,
            child: Text(
              label,
              style: AboutTactileLensScreenStyles.projectLabelStyle,
            ),
          ),
          const SizedBox(width: AboutTactileLensScreenStyles.space8),
          Expanded(
            child: Transform.translate(
              offset: AboutTactileLensScreenStyles.projectValueOffset,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: AboutTactileLensScreenStyles.projectValueStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutProjectCard extends StatelessWidget {
  const _AboutProjectCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AboutTactileLensScreenStyles.footerCardPadding,
      decoration: const BoxDecoration(
        gradient: AboutTactileLensScreenStyles.heroGradient,
        borderRadius: AboutTactileLensScreenStyles.cardRadius,
        border: AboutTactileLensScreenStyles.cardBorder,
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _FooterIcon(),
          SizedBox(width: AboutTactileLensScreenStyles.space14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'About This Project',
                  style: AboutTactileLensScreenStyles.footerTitleStyle,
                ),
                SizedBox(height: AboutTactileLensScreenStyles.space6),
                Text(
                  'TactileLens is a capstone project developed by BSIT students of Holy Cross of Davao College. It aims to promote accessibility in education through technology and innovation.',
                  style: AboutTactileLensScreenStyles.footerBodyStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterIcon extends StatelessWidget {
  const _FooterIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AboutTactileLensScreenStyles.smallIconPadding,
      decoration: const BoxDecoration(
        color: AboutTactileLensScreenStyles.primarySoftColor,
        borderRadius: AboutTactileLensScreenStyles.iconRadius,
      ),
      child: const Icon(
        AboutTactileLensScreenStyles.aboutProjectIcon,
        color: AboutTactileLensScreenStyles.primaryAccentColor,
        size: AboutTactileLensScreenStyles.footerIconSize,
      ),
    );
  }
}

class _FeatureData {
  const _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
