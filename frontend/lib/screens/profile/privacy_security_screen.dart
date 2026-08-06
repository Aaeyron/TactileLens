import 'package:flutter/material.dart';

import '../../styles/screens/profile/privacy_security_screen_styles.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  static const List<_PrivacyTopicData> _topics = <_PrivacyTopicData>[
    _PrivacyTopicData(
      icon: PrivacySecurityScreenStyles.dataProtectionIcon,
      title: 'Data Protection',
      description:
          'Your materials, translations, and personal data are handled securely and never shared.',
    ),
    _PrivacyTopicData(
      icon: PrivacySecurityScreenStyles.offlinePrivacyIcon,
      title: 'Offline Privacy',
      description:
          'Scan, store, and translate without internet. Your data stays on your device for private use.',
    ),
    _PrivacyTopicData(
      icon: PrivacySecurityScreenStyles.onlineSecurityIcon,
      title: 'Online Security',
      description:
          'When you use online features, your data is transmitted and stored securely.',
    ),
    _PrivacyTopicData(
      icon: PrivacySecurityScreenStyles.accountAccessIcon,
      title: 'Account & Access',
      description:
          'Your account is protected with secure login and controlled access to your data.',
    ),
    _PrivacyTopicData(
      icon: PrivacySecurityScreenStyles.permissionsIcon,
      title: 'Permissions',
      description:
          'Camera, storage, and file access are used only for app features you use.',
    ),
    _PrivacyTopicData(
      icon: PrivacySecurityScreenStyles.controlIcon,
      title: 'Your Control',
      description:
          'Review, manage, and delete your saved materials and translations anytime.',
    ),
  ];

  static const List<_SecurityFeatureData> _features = <_SecurityFeatureData>[
    _SecurityFeatureData(
      icon: PrivacySecurityScreenStyles.secureScanIcon,
      title: 'Secure Scan',
      description: 'Safe camera use for scanning content',
    ),
    _SecurityFeatureData(
      icon: PrivacySecurityScreenStyles.offlineFeatureIcon,
      title: 'Offline Private',
      description: 'Works offline. Your data stays local.',
    ),
    _SecurityFeatureData(
      icon: PrivacySecurityScreenStyles.protectedOnlineIcon,
      title: 'Protected Online',
      description: 'Secure connections for online features',
    ),
    _SecurityFeatureData(
      icon: PrivacySecurityScreenStyles.permissionControlIcon,
      title: 'Permission Control',
      description: 'Only required permissions are used',
    ),
    _SecurityFeatureData(
      icon: PrivacySecurityScreenStyles.savedMaterialsIcon,
      title: 'Saved Materials',
      description: 'Organize and protect your materials',
    ),
    _SecurityFeatureData(
      icon: PrivacySecurityScreenStyles.userControlIcon,
      title: 'User Control',
      description: 'Manage, review, and delete your data',
    ),
  ];

  static const List<_OverviewData> _overviewItems = <_OverviewData>[
    _OverviewData(
      title: 'Works Offline',
      description: 'Full access without internet.',
    ),
    _OverviewData(
      title: 'Supports Secure Online Use',
      description: 'Your data is protected.',
    ),
    _OverviewData(
      title: 'Personal data is protected',
      description: 'We never sell your data.',
    ),
    _OverviewData(
      title: 'Only required permissions are used',
      description: 'Nothing extra.',
    ),
    _OverviewData(
      title: 'Users control saved content',
      description: 'Review, manage, or delete anytime.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrivacySecurityScreenStyles.backgroundColor,
      appBar: AppBar(
        elevation: PrivacySecurityScreenStyles.appBarElevation,
        scrolledUnderElevation:
            PrivacySecurityScreenStyles.appBarScrolledUnderElevation,
        backgroundColor: PrivacySecurityScreenStyles.cardColor,
        foregroundColor: PrivacySecurityScreenStyles.textPrimaryColor,
        centerTitle: true,
        title: const Text(
          'Privacy & Security',
          style: PrivacySecurityScreenStyles.appBarTitleStyle,
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: PrivacySecurityScreenStyles.screenPadding,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: PrivacySecurityScreenStyles.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const _PrivacyHero(),
                  const SizedBox(height: PrivacySecurityScreenStyles.space12),
                  ..._topics.map(
                    (_PrivacyTopicData topic) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: PrivacySecurityScreenStyles.space10,
                      ),
                      child: _PrivacyTopicCard(topic: topic),
                    ),
                  ),
                  const Text(
                    'Key Security Features',
                    style: PrivacySecurityScreenStyles.sectionTitleStyle,
                  ),
                  const SizedBox(height: PrivacySecurityScreenStyles.space10),
                  const _SecurityFeatureGrid(features: _features),
                  const SizedBox(height: PrivacySecurityScreenStyles.space14),
                  const _PrivacyOverview(items: _overviewItems),
                  const SizedBox(height: PrivacySecurityScreenStyles.space16),
                  const _BrandFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyHero extends StatelessWidget {
  const _PrivacyHero();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth <
            PrivacySecurityScreenStyles.compactBreakpoint;
        return Container(
          padding: compact
              ? PrivacySecurityScreenStyles.compactHeroPadding
              : PrivacySecurityScreenStyles.heroPadding,
          decoration: const BoxDecoration(
            gradient: PrivacySecurityScreenStyles.heroGradient,
            borderRadius: PrivacySecurityScreenStyles.cardRadius,
            border: PrivacySecurityScreenStyles.cardBorder,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: compact
                    ? PrivacySecurityScreenStyles.compactHeroIconBoxSize
                    : PrivacySecurityScreenStyles.heroIconBoxSize,
                height: compact
                    ? PrivacySecurityScreenStyles.compactHeroIconBoxSize
                    : PrivacySecurityScreenStyles.heroIconBoxSize,
                child: const _HeroShield(),
              ),
              const SizedBox(width: PrivacySecurityScreenStyles.space18),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Privacy & Security',
                        maxLines: 1,
                        style: PrivacySecurityScreenStyles.heroTitleStyle,
                      ),
                    ),
                    SizedBox(height: PrivacySecurityScreenStyles.space6),
                    Text(
                      'Your data stays protected whether you work offline or online.',
                      style: PrivacySecurityScreenStyles.heroSubtitleStyle,
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

class _HeroShield extends StatelessWidget {
  const _HeroShield();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: PrivacySecurityScreenStyles.iconGradient,
        borderRadius: PrivacySecurityScreenStyles.heroIconRadius,
        boxShadow: PrivacySecurityScreenStyles.heroIconShadow,
      ),
      child: const Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Icon(
            PrivacySecurityScreenStyles.heroIcon,
            color: PrivacySecurityScreenStyles.cardColor,
            size: PrivacySecurityScreenStyles.heroIconSize,
          ),
          Icon(
            PrivacySecurityScreenStyles.heroLockIcon,
            color: PrivacySecurityScreenStyles.primaryColor,
            size: PrivacySecurityScreenStyles.heroLockIconSize,
          ),
        ],
      ),
    );
  }
}

class _PrivacyTopicCard extends StatelessWidget {
  const _PrivacyTopicCard({required this.topic});

  final _PrivacyTopicData topic;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth <
            PrivacySecurityScreenStyles.compactBreakpoint;
        return Material(
          color: PrivacySecurityScreenStyles.cardColor,
          borderRadius: PrivacySecurityScreenStyles.cardRadius,
          child: InkWell(
            onTap: topic.onTap,
            borderRadius: PrivacySecurityScreenStyles.cardRadius,
            child: Container(
              padding: compact
                  ? PrivacySecurityScreenStyles.compactTopicCardPadding
                  : PrivacySecurityScreenStyles.topicCardPadding,
              decoration: const BoxDecoration(
                borderRadius: PrivacySecurityScreenStyles.cardRadius,
                border: PrivacySecurityScreenStyles.cardBorder,
                boxShadow: PrivacySecurityScreenStyles.cardShadow,
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: compact
                        ? PrivacySecurityScreenStyles.compactTopicIconBoxSize
                        : PrivacySecurityScreenStyles.topicIconBoxSize,
                    height: compact
                        ? PrivacySecurityScreenStyles.compactTopicIconBoxSize
                        : PrivacySecurityScreenStyles.topicIconBoxSize,
                    decoration: const BoxDecoration(
                      color: PrivacySecurityScreenStyles.primarySoftColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      topic.icon,
                      color: PrivacySecurityScreenStyles.primaryColor,
                      size: PrivacySecurityScreenStyles.topicIconSize,
                    ),
                  ),
                  const SizedBox(width: PrivacySecurityScreenStyles.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          topic.title,
                          style: PrivacySecurityScreenStyles.topicTitleStyle,
                        ),
                        const SizedBox(
                          height: PrivacySecurityScreenStyles.space4,
                        ),
                        Text(
                          topic.description,
                          maxLines: PrivacySecurityScreenStyles
                              .topicDescriptionMaxLines,
                          overflow: TextOverflow.ellipsis,
                          style: PrivacySecurityScreenStyles
                              .topicDescriptionStyle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: PrivacySecurityScreenStyles.space8),
                  const Icon(
                    PrivacySecurityScreenStyles.arrowIcon,
                    color: PrivacySecurityScreenStyles.primaryColor,
                    size: PrivacySecurityScreenStyles.arrowIconSize,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SecurityFeatureGrid extends StatelessWidget {
  const _SecurityFeatureGrid({required this.features});

  final List<_SecurityFeatureData> features;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth <
            PrivacySecurityScreenStyles.compactBreakpoint;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: features.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: compact
                ? PrivacySecurityScreenStyles.compactGridColumns
                : PrivacySecurityScreenStyles.regularGridColumns,
            crossAxisSpacing: PrivacySecurityScreenStyles.gridSpacing,
            mainAxisSpacing: PrivacySecurityScreenStyles.gridSpacing,
            childAspectRatio: compact
                ? PrivacySecurityScreenStyles.compactGridAspectRatio
                : PrivacySecurityScreenStyles.regularGridAspectRatio,
          ),
          itemBuilder: (BuildContext context, int index) {
            return _SecurityFeatureCard(feature: features[index]);
          },
        );
      },
    );
  }
}

class _SecurityFeatureCard extends StatelessWidget {
  const _SecurityFeatureCard({required this.feature});

  final _SecurityFeatureData feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: PrivacySecurityScreenStyles.featureCardPadding,
      decoration: const BoxDecoration(
        color: PrivacySecurityScreenStyles.cardColor,
        borderRadius: PrivacySecurityScreenStyles.cardRadius,
        border: PrivacySecurityScreenStyles.cardBorder,
        boxShadow: PrivacySecurityScreenStyles.cardShadow,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: PrivacySecurityScreenStyles.featureIconBoxSize,
            height: PrivacySecurityScreenStyles.featureIconBoxSize,
            decoration: const BoxDecoration(
              gradient: PrivacySecurityScreenStyles.iconGradient,
              borderRadius: PrivacySecurityScreenStyles.iconRadius,
            ),
            child: Icon(
              feature.icon,
              color: PrivacySecurityScreenStyles.cardColor,
              size: PrivacySecurityScreenStyles.featureIconSize,
            ),
          ),
          const SizedBox(width: PrivacySecurityScreenStyles.space10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  feature.title,
                  maxLines: PrivacySecurityScreenStyles
                      .featureDescriptionMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: PrivacySecurityScreenStyles.featureTitleStyle,
                ),
                const SizedBox(height: PrivacySecurityScreenStyles.space4),
                Text(
                  feature.description,
                  maxLines: PrivacySecurityScreenStyles
                      .featureDescriptionMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: PrivacySecurityScreenStyles.featureDescriptionStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyOverview extends StatelessWidget {
  const _PrivacyOverview({required this.items});

  final List<_OverviewData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: PrivacySecurityScreenStyles.overviewPadding,
      decoration: const BoxDecoration(
        color: PrivacySecurityScreenStyles.cardColor,
        borderRadius: PrivacySecurityScreenStyles.cardRadius,
        border: PrivacySecurityScreenStyles.cardBorder,
        boxShadow: PrivacySecurityScreenStyles.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(
                PrivacySecurityScreenStyles.overviewIcon,
                color: PrivacySecurityScreenStyles.primaryColor,
                size: PrivacySecurityScreenStyles.overviewIconSize,
              ),
              SizedBox(width: PrivacySecurityScreenStyles.space12),
              Text(
                'Privacy Overview',
                style: PrivacySecurityScreenStyles.overviewTitleStyle,
              ),
            ],
          ),
          const SizedBox(height: PrivacySecurityScreenStyles.space14),
          ...items.map(
            (_OverviewData item) => Padding(
              padding: const EdgeInsets.only(
                bottom: PrivacySecurityScreenStyles.space8,
              ),
              child: _OverviewRow(item: item),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({required this.item});

  final _OverviewData item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(
          PrivacySecurityScreenStyles.checkIcon,
          color: PrivacySecurityScreenStyles.primaryColor,
          size: PrivacySecurityScreenStyles.checkIconSize,
        ),
        const SizedBox(width: PrivacySecurityScreenStyles.space10),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: item.title,
                  style: PrivacySecurityScreenStyles.overviewEmphasisStyle,
                ),
                TextSpan(
                  text: ' — ${item.description}',
                  style: PrivacySecurityScreenStyles.overviewTextStyle,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandFooter extends StatelessWidget {
  const _BrandFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: PrivacySecurityScreenStyles.footerPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            PrivacySecurityScreenStyles.brandIcon,
            color: PrivacySecurityScreenStyles.primaryColor,
            size: PrivacySecurityScreenStyles.brandIconSize,
          ),
          const SizedBox(width: PrivacySecurityScreenStyles.space12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const <Widget>[
              Text(
                'TactileLens',
                style: PrivacySecurityScreenStyles.brandTitleStyle,
              ),
              Text(
                'See. Translate. Empower.',
                style: PrivacySecurityScreenStyles.brandTaglineStyle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrivacyTopicData {
  const _PrivacyTopicData({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
}

class _SecurityFeatureData {
  const _SecurityFeatureData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _OverviewData {
  const _OverviewData({required this.title, required this.description});

  final String title;
  final String description;
}
