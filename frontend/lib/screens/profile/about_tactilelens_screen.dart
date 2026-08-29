import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../styles/screens/profile/about_tactilelens_screen_styles.dart';

class AboutTactileLensScreen extends StatelessWidget {
  const AboutTactileLensScreen({super.key});

  static const List<_FeatureData> _features = <_FeatureData>[
    _FeatureData(
      icon: AboutTactileLensScreenStyles.scanIcon,
      title: 'Smart Scan',
      description: 'Capture or upload printed text and mathematical content.',
    ),
    _FeatureData(
      icon: AboutTactileLensScreenStyles.aiIcon,
      title: 'AI Assisted',
      description: 'Recognize learning content using intelligent document AI.',
    ),
    _FeatureData(
      icon: AboutTactileLensScreenStyles.brailleIcon,
      title: 'Accessible Output',
      description: 'Translate recognized content into UEB and Nemeth Braille.',
    ),
    _FeatureData(
      icon: AboutTactileLensScreenStyles.offlineIcon,
      title: 'Offline First',
      description: 'Keep essential learning materials available on the device.',
    ),
    _FeatureData(
      icon: AboutTactileLensScreenStyles.organizedIcon,
      title: 'Organized',
      description: 'Save scans and arrange accessible materials into folders.',
    ),
    _FeatureData(
      icon: AboutTactileLensScreenStyles.privacyIcon,
      title: 'Secure & Private',
      description:
          'Protect account information and locally stored learning data.',
    ),
  ];

  static const List<_ProjectData> _projectInformation = <_ProjectData>[
    _ProjectData(
      icon: AboutTactileLensScreenStyles.projectTypeIcon,
      label: 'Project Type',
      value: 'Capstone Project',
    ),
    _ProjectData(
      icon: AboutTactileLensScreenStyles.institutionIcon,
      label: 'Institution',
      value: 'Holy Cross of Davao College',
    ),
    _ProjectData(
      icon: AboutTactileLensScreenStyles.courseIcon,
      label: 'Course',
      value: 'BS Information Technology',
    ),
    _ProjectData(
      icon: AboutTactileLensScreenStyles.yearIcon,
      label: 'Academic Year',
      value: 'AY 2025–2026',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AboutTactileLensScreenStyles.backgroundColor,
        body: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: AboutTactileLensScreenStyles.entranceDuration,
          curve: AboutTactileLensScreenStyles.entranceCurve,
          builder:
              (BuildContext context, double animationValue, Widget? child) {
                return Opacity(
                  opacity: animationValue,
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      AboutTactileLensScreenStyles.entranceVerticalOffset *
                          (1 - animationValue),
                    ),
                    child: child,
                  ),
                );
              },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: <Widget>[
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverPadding(
                padding: AboutTactileLensScreenStyles.contentPadding,
                sliver: SliverList(
                  delegate: SliverChildListDelegate.fixed(<Widget>[
                    const _BrandCard(),
                    const SizedBox(
                      height: AboutTactileLensScreenStyles.sectionSpacing,
                    ),
                    const _InformationCard(
                      icon: AboutTactileLensScreenStyles.missionIcon,
                      title: AboutTactileLensScreenStyles.missionTitle,
                      description:
                          AboutTactileLensScreenStyles.missionDescription,
                    ),
                    const SizedBox(
                      height: AboutTactileLensScreenStyles.cardSpacing,
                    ),
                    const _InformationCard(
                      icon: AboutTactileLensScreenStyles.overviewIcon,
                      title: AboutTactileLensScreenStyles.overviewTitle,
                      description:
                          AboutTactileLensScreenStyles.overviewDescription,
                    ),
                    const SizedBox(
                      height: AboutTactileLensScreenStyles.sectionSpacing,
                    ),
                    const _SectionHeading(
                      title: AboutTactileLensScreenStyles.featuresTitle,
                      description:
                          AboutTactileLensScreenStyles.featuresDescription,
                    ),
                    const SizedBox(
                      height: AboutTactileLensScreenStyles.headingBottomSpacing,
                    ),
                    const _FeatureGrid(features: _features),
                    const SizedBox(
                      height: AboutTactileLensScreenStyles.sectionSpacing,
                    ),
                    const _SectionHeading(
                      title: AboutTactileLensScreenStyles.projectTitle,
                      description:
                          AboutTactileLensScreenStyles.projectDescription,
                    ),
                    const SizedBox(
                      height: AboutTactileLensScreenStyles.headingBottomSpacing,
                    ),
                    const _ProjectCard(projectInformation: _projectInformation),
                    const SizedBox(
                      height: AboutTactileLensScreenStyles.cardSpacing,
                    ),
                    const _ProjectPurposeCard(),
                    const SizedBox(
                      height: AboutTactileLensScreenStyles.bottomSpacing,
                    ),
                  ]),
                ),
              ),
            ],
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
        AboutTactileLensScreenStyles.headerHorizontalPadding,
        statusBarHeight + AboutTactileLensScreenStyles.headerTopPadding,
        AboutTactileLensScreenStyles.headerHorizontalPadding,
        AboutTactileLensScreenStyles.headerBottomPadding,
      ),
      decoration: const BoxDecoration(
        gradient: AboutTactileLensScreenStyles.headerGradient,
        borderRadius: AboutTactileLensScreenStyles.headerRadius,
      ),
      child: Stack(
        children: <Widget>[
          const Positioned(
            right: AboutTactileLensScreenStyles.decorationRight,
            bottom: AboutTactileLensScreenStyles.decorationBottom,
            child: _HeaderBrailleDecoration(),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    tooltip: AboutTactileLensScreenStyles.backTooltip,
                    onPressed: () {
                      Navigator.of(context).maybePop();
                    },
                    style: AboutTactileLensScreenStyles.backButtonStyle,
                    icon: const Icon(
                      AboutTactileLensScreenStyles.backIcon,
                      size: AboutTactileLensScreenStyles.backIconSize,
                    ),
                  ),
                  const SizedBox(
                    width: AboutTactileLensScreenStyles.headerBackSpacing,
                  ),
                  const Expanded(
                    child: Text(
                      AboutTactileLensScreenStyles.screenTitle,
                      style: AboutTactileLensScreenStyles.headerTitleStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: AboutTactileLensScreenStyles.headerTextSpacing,
              ),
              const Padding(
                padding: AboutTactileLensScreenStyles.headerDescriptionPadding,
                child: SizedBox(
                  width: AboutTactileLensScreenStyles.headerDescriptionWidth,
                  child: Text(
                    AboutTactileLensScreenStyles.screenDescription,
                    style: AboutTactileLensScreenStyles.headerDescriptionStyle,
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

class _BrandCard extends StatelessWidget {
  const _BrandCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AboutTactileLensScreenStyles.brandCardPadding,
      decoration: const BoxDecoration(
        color: AboutTactileLensScreenStyles.surfaceColor,
        borderRadius: AboutTactileLensScreenStyles.cardRadius,
        border: AboutTactileLensScreenStyles.cardBorder,
        boxShadow: AboutTactileLensScreenStyles.cardShadow,
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: AboutTactileLensScreenStyles.logoContainerSize,
            height: AboutTactileLensScreenStyles.logoContainerSize,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: AboutTactileLensScreenStyles.logoGradient,
              borderRadius: AboutTactileLensScreenStyles.logoRadius,
              boxShadow: AboutTactileLensScreenStyles.logoShadow,
            ),
            child: const Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Icon(
                  AboutTactileLensScreenStyles.logoIcon,
                  color: AboutTactileLensScreenStyles.surfaceColor,
                  size: AboutTactileLensScreenStyles.logoIconSize,
                ),
                Positioned(
                  right: AboutTactileLensScreenStyles.logoDotsRight,
                  bottom: AboutTactileLensScreenStyles.logoDotsBottom,
                  child: _SmallBrailleDecoration(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AboutTactileLensScreenStyles.brandNameSpacing),
          const Text(
            AboutTactileLensScreenStyles.appName,
            textAlign: TextAlign.center,
            style: AboutTactileLensScreenStyles.brandTitleStyle,
          ),
          const SizedBox(height: AboutTactileLensScreenStyles.taglineSpacing),
          const Text(
            AboutTactileLensScreenStyles.tagline,
            textAlign: TextAlign.center,
            style: AboutTactileLensScreenStyles.taglineStyle,
          ),
          const SizedBox(height: AboutTactileLensScreenStyles.versionSpacing),
          Container(
            padding: AboutTactileLensScreenStyles.versionBadgePadding,
            decoration: const BoxDecoration(
              color: AboutTactileLensScreenStyles.primarySoftColor,
              borderRadius: AboutTactileLensScreenStyles.versionBadgeRadius,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  AboutTactileLensScreenStyles.verifiedIcon,
                  color: AboutTactileLensScreenStyles.primaryColor,
                  size: AboutTactileLensScreenStyles.versionIconSize,
                ),
                SizedBox(
                  width: AboutTactileLensScreenStyles.versionIconSpacing,
                ),
                Text(
                  AboutTactileLensScreenStyles.versionLabel,
                  style: AboutTactileLensScreenStyles.versionTextStyle,
                ),
              ],
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
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AboutTactileLensScreenStyles.informationCardPadding,
      decoration: const BoxDecoration(
        color: AboutTactileLensScreenStyles.surfaceColor,
        borderRadius: AboutTactileLensScreenStyles.cardRadius,
        border: AboutTactileLensScreenStyles.cardBorder,
        boxShadow: AboutTactileLensScreenStyles.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _IconContainer(icon: icon),
          const SizedBox(
            width: AboutTactileLensScreenStyles.informationContentSpacing,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AboutTactileLensScreenStyles.cardTitleStyle),
                const SizedBox(
                  height: AboutTactileLensScreenStyles.cardDescriptionSpacing,
                ),
                Text(
                  description,
                  style: AboutTactileLensScreenStyles.bodyStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: AboutTactileLensScreenStyles.sectionTitleStyle),
        const SizedBox(
          height: AboutTactileLensScreenStyles.sectionDescriptionSpacing,
        ),
        Text(
          description,
          style: AboutTactileLensScreenStyles.sectionDescriptionStyle,
        ),
      ],
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
        final bool useSingleColumn =
            constraints.maxWidth <
            AboutTactileLensScreenStyles.featureSingleColumnBreakpoint;

        final double itemWidth = useSingleColumn
            ? constraints.maxWidth
            : (constraints.maxWidth -
                      AboutTactileLensScreenStyles.featureSpacing) /
                  2;

        return Wrap(
          spacing: AboutTactileLensScreenStyles.featureSpacing,
          runSpacing: AboutTactileLensScreenStyles.featureSpacing,
          children: features
              .map((_FeatureData feature) {
                return SizedBox(
                  width: itemWidth,
                  child: _FeatureCard(feature: feature),
                );
              })
              .toList(growable: false),
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
      constraints: const BoxConstraints(
        minHeight: AboutTactileLensScreenStyles.featureMinimumHeight,
      ),
      padding: AboutTactileLensScreenStyles.featureCardPadding,
      decoration: const BoxDecoration(
        color: AboutTactileLensScreenStyles.surfaceColor,
        borderRadius: AboutTactileLensScreenStyles.featureRadius,
        border: AboutTactileLensScreenStyles.cardBorder,
        boxShadow: AboutTactileLensScreenStyles.featureShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _IconContainer(icon: feature.icon),
          const SizedBox(
            height: AboutTactileLensScreenStyles.featureTitleSpacing,
          ),
          Text(
            feature.title,
            style: AboutTactileLensScreenStyles.featureTitleStyle,
          ),
          const SizedBox(
            height: AboutTactileLensScreenStyles.featureDescriptionSpacing,
          ),
          Text(
            feature.description,
            style: AboutTactileLensScreenStyles.featureBodyStyle,
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.projectInformation});

  final List<_ProjectData> projectInformation;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AboutTactileLensScreenStyles.surfaceColor,
        borderRadius: AboutTactileLensScreenStyles.cardRadius,
        border: AboutTactileLensScreenStyles.cardBorder,
        boxShadow: AboutTactileLensScreenStyles.cardShadow,
      ),
      child: Column(
        children: List<Widget>.generate(projectInformation.length, (int index) {
          return _ProjectRow(
            data: projectInformation[index],
            showDivider: index != projectInformation.length - 1,
          );
        }, growable: false),
      ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({required this.data, required this.showDivider});

  final _ProjectData data;
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
          _IconContainer(icon: data.icon, compact: true),
          const SizedBox(
            width: AboutTactileLensScreenStyles.projectContentSpacing,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  data.label,
                  style: AboutTactileLensScreenStyles.projectLabelStyle,
                ),
                const SizedBox(
                  height: AboutTactileLensScreenStyles.projectValueSpacing,
                ),
                Text(
                  data.value,
                  style: AboutTactileLensScreenStyles.projectValueStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectPurposeCard extends StatelessWidget {
  const _ProjectPurposeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AboutTactileLensScreenStyles.purposeCardPadding,
      decoration: const BoxDecoration(
        gradient: AboutTactileLensScreenStyles.purposeGradient,
        borderRadius: AboutTactileLensScreenStyles.cardRadius,
        boxShadow: AboutTactileLensScreenStyles.cardShadow,
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            AboutTactileLensScreenStyles.educatorIcon,
            color: AboutTactileLensScreenStyles.surfaceColor,
            size: AboutTactileLensScreenStyles.purposeIconSize,
          ),
          SizedBox(width: AboutTactileLensScreenStyles.purposeContentSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AboutTactileLensScreenStyles.purposeTitle,
                  style: AboutTactileLensScreenStyles.purposeTitleStyle,
                ),
                SizedBox(
                  height:
                      AboutTactileLensScreenStyles.purposeDescriptionSpacing,
                ),
                Text(
                  AboutTactileLensScreenStyles.purposeDescription,
                  style: AboutTactileLensScreenStyles.purposeBodyStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconContainer extends StatelessWidget {
  const _IconContainer({required this.icon, this.compact = false});

  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double size = compact
        ? AboutTactileLensScreenStyles.compactIconContainerSize
        : AboutTactileLensScreenStyles.iconContainerSize;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AboutTactileLensScreenStyles.primarySoftColor,
        borderRadius: AboutTactileLensScreenStyles.iconContainerRadius,
      ),
      child: Icon(
        icon,
        color: AboutTactileLensScreenStyles.primaryColor,
        size: compact
            ? AboutTactileLensScreenStyles.compactIconSize
            : AboutTactileLensScreenStyles.informationIconSize,
      ),
    );
  }
}

class _HeaderBrailleDecoration extends StatelessWidget {
  const _HeaderBrailleDecoration();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: AboutTactileLensScreenStyles.decorationOpacity,
      child: SizedBox(
        width: AboutTactileLensScreenStyles.decorationWidth,
        child: Wrap(
          spacing: AboutTactileLensScreenStyles.decorationDotSpacing,
          runSpacing: AboutTactileLensScreenStyles.decorationDotSpacing,
          children: List<Widget>.generate(
            AboutTactileLensScreenStyles.decorationDotCount,
            (int index) {
              return const DecoratedBox(
                decoration: BoxDecoration(
                  color: AboutTactileLensScreenStyles.surfaceColor,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: AboutTactileLensScreenStyles.decorationDotSize,
                  height: AboutTactileLensScreenStyles.decorationDotSize,
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

class _SmallBrailleDecoration extends StatelessWidget {
  const _SmallBrailleDecoration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AboutTactileLensScreenStyles.smallDotsWidth,
      child: Wrap(
        spacing: AboutTactileLensScreenStyles.smallDotSpacing,
        runSpacing: AboutTactileLensScreenStyles.smallDotSpacing,
        children: List<Widget>.generate(
          AboutTactileLensScreenStyles.smallDotCount,
          (int index) {
            return const DecoratedBox(
              decoration: BoxDecoration(
                color: AboutTactileLensScreenStyles.surfaceColor,
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: AboutTactileLensScreenStyles.smallDotSize,
                height: AboutTactileLensScreenStyles.smallDotSize,
              ),
            );
          },
          growable: false,
        ),
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

class _ProjectData {
  const _ProjectData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}
