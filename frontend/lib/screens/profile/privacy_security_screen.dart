import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../styles/screens/profile/privacy_security_screen_styles.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  static const List<_PrivacyTopicData> _topics = <_PrivacyTopicData>[
    _PrivacyTopicData(
      icon: PrivacySecurityScreenStyles.dataProtectionIcon,
      title: 'Data Protection',
      description:
          'Account information, materials, and translations are handled using '
          'appropriate safeguards.',
    ),
    _PrivacyTopicData(
      icon: PrivacySecurityScreenStyles.offlinePrivacyIcon,
      title: 'Offline Privacy',
      description:
          'Guest scans, history, and materials can remain stored locally on '
          'the device.',
    ),
    _PrivacyTopicData(
      icon: PrivacySecurityScreenStyles.onlineSecurityIcon,
      title: 'Secure Online Access',
      description:
          'Online account and AI features use protected connections when they '
          'are available.',
    ),
    _PrivacyTopicData(
      icon: PrivacySecurityScreenStyles.accountAccessIcon,
      title: 'Account Access',
      description:
          'Authenticated accounts require valid credentials before accessing '
          'synchronized information.',
    ),
    _PrivacyTopicData(
      icon: PrivacySecurityScreenStyles.permissionsIcon,
      title: 'Device Permissions',
      description:
          'Camera and file access are requested only when required by features '
          'you choose to use.',
    ),
    _PrivacyTopicData(
      icon: PrivacySecurityScreenStyles.controlIcon,
      title: 'Your Control',
      description:
          'You can review and delete locally saved scans, history, folders, '
          'and learning materials.',
    ),
  ];

  static const List<_SecurityFeatureData> _securityFeatures =
      <_SecurityFeatureData>[
        _SecurityFeatureData(
          icon: PrivacySecurityScreenStyles.secureScanIcon,
          title: 'Secure scanning',
        ),
        _SecurityFeatureData(
          icon: PrivacySecurityScreenStyles.offlineFeatureIcon,
          title: 'Offline storage',
        ),
        _SecurityFeatureData(
          icon: PrivacySecurityScreenStyles.protectedOnlineIcon,
          title: 'Protected connections',
        ),
        _SecurityFeatureData(
          icon: PrivacySecurityScreenStyles.permissionControlIcon,
          title: 'Permission control',
        ),
        _SecurityFeatureData(
          icon: PrivacySecurityScreenStyles.savedMaterialsIcon,
          title: 'Local materials',
        ),
        _SecurityFeatureData(
          icon: PrivacySecurityScreenStyles.userControlIcon,
          title: 'User-managed data',
        ),
      ];

  static const List<_OverviewData> _overviewItems = <_OverviewData>[
    _OverviewData(
      title: 'Guest Mode',
      description: 'Supported data is stored locally on the device.',
    ),
    _OverviewData(
      title: 'Registered Accounts',
      description: 'Authentication protects access to synchronized data.',
    ),
    _OverviewData(
      title: 'Document Processing',
      description: 'Images are used only to provide requested scan results.',
    ),
    _OverviewData(
      title: 'Device Permissions',
      description: 'Only permissions required by active features are used.',
    ),
    _OverviewData(
      title: 'Content Management',
      description: 'Saved information can be reviewed and deleted by users.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: PrivacySecurityScreenStyles.backgroundColor,
        body: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: PrivacySecurityScreenStyles.entranceDuration,
          curve: PrivacySecurityScreenStyles.entranceCurve,
          builder:
              (BuildContext context, double animationValue, Widget? child) {
                return Opacity(
                  opacity: animationValue,
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      PrivacySecurityScreenStyles.entranceVerticalOffset *
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
                padding: PrivacySecurityScreenStyles.contentPadding,
                sliver: SliverList(
                  delegate: SliverChildListDelegate.fixed(<Widget>[
                    const _SecurityStatusCard(),
                    const SizedBox(
                      height: PrivacySecurityScreenStyles.sectionSpacing,
                    ),
                    const _SectionHeading(
                      title: PrivacySecurityScreenStyles.privacyTopicsTitle,
                      description:
                          PrivacySecurityScreenStyles.privacyTopicsDescription,
                    ),
                    const SizedBox(
                      height: PrivacySecurityScreenStyles.headingBottomSpacing,
                    ),
                    const _PrivacyTopicsCard(topics: _topics),
                    const SizedBox(
                      height: PrivacySecurityScreenStyles.sectionSpacing,
                    ),
                    const _SectionHeading(
                      title: PrivacySecurityScreenStyles.securityFeaturesTitle,
                      description: PrivacySecurityScreenStyles
                          .securityFeaturesDescription,
                    ),
                    const SizedBox(
                      height: PrivacySecurityScreenStyles.headingBottomSpacing,
                    ),
                    const _SecurityFeatureGrid(features: _securityFeatures),
                    const SizedBox(
                      height: PrivacySecurityScreenStyles.sectionSpacing,
                    ),
                    const _PrivacyOverview(items: _overviewItems),
                    const SizedBox(
                      height: PrivacySecurityScreenStyles.cardSpacing,
                    ),
                    const _PrivacyPromiseCard(),
                    const SizedBox(
                      height: PrivacySecurityScreenStyles.bottomSpacing,
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
        PrivacySecurityScreenStyles.headerHorizontalPadding,
        statusBarHeight + PrivacySecurityScreenStyles.headerTopPadding,
        PrivacySecurityScreenStyles.headerHorizontalPadding,
        PrivacySecurityScreenStyles.headerBottomPadding,
      ),
      decoration: const BoxDecoration(
        gradient: PrivacySecurityScreenStyles.headerGradient,
        borderRadius: PrivacySecurityScreenStyles.headerRadius,
      ),
      child: Stack(
        children: <Widget>[
          const Positioned(
            right: PrivacySecurityScreenStyles.decorationRight,
            bottom: PrivacySecurityScreenStyles.decorationBottom,
            child: _HeaderBrailleDecoration(),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    tooltip: PrivacySecurityScreenStyles.backTooltip,
                    onPressed: () {
                      Navigator.of(context).maybePop();
                    },
                    style: PrivacySecurityScreenStyles.backButtonStyle,
                    icon: const Icon(
                      PrivacySecurityScreenStyles.backIcon,
                      size: PrivacySecurityScreenStyles.backIconSize,
                    ),
                  ),
                  const SizedBox(
                    width: PrivacySecurityScreenStyles.headerBackSpacing,
                  ),
                  const Expanded(
                    child: Text(
                      PrivacySecurityScreenStyles.screenTitle,
                      style: PrivacySecurityScreenStyles.headerTitleStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: PrivacySecurityScreenStyles.headerTextSpacing,
              ),
              const Padding(
                padding: PrivacySecurityScreenStyles.headerDescriptionPadding,
                child: SizedBox(
                  width: PrivacySecurityScreenStyles.headerDescriptionWidth,
                  child: Text(
                    PrivacySecurityScreenStyles.screenDescription,
                    style: PrivacySecurityScreenStyles.headerDescriptionStyle,
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

class _SecurityStatusCard extends StatelessWidget {
  const _SecurityStatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: PrivacySecurityScreenStyles.statusCardPadding,
      decoration: const BoxDecoration(
        color: PrivacySecurityScreenStyles.surfaceColor,
        borderRadius: PrivacySecurityScreenStyles.cardRadius,
        border: PrivacySecurityScreenStyles.cardBorder,
        boxShadow: PrivacySecurityScreenStyles.cardShadow,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: PrivacySecurityScreenStyles.statusIconContainerSize,
            height: PrivacySecurityScreenStyles.statusIconContainerSize,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: PrivacySecurityScreenStyles.securityGradient,
              borderRadius: PrivacySecurityScreenStyles.statusIconRadius,
              boxShadow: PrivacySecurityScreenStyles.statusIconShadow,
            ),
            child: const Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Icon(
                  PrivacySecurityScreenStyles.heroIcon,
                  color: PrivacySecurityScreenStyles.surfaceColor,
                  size: PrivacySecurityScreenStyles.statusShieldSize,
                ),
                Icon(
                  PrivacySecurityScreenStyles.heroLockIcon,
                  color: PrivacySecurityScreenStyles.primaryColor,
                  size: PrivacySecurityScreenStyles.statusLockSize,
                ),
              ],
            ),
          ),
          const SizedBox(
            width: PrivacySecurityScreenStyles.statusContentSpacing,
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        PrivacySecurityScreenStyles.statusTitle,
                        style: PrivacySecurityScreenStyles.statusTitleStyle,
                      ),
                    ),
                    SizedBox(
                      width: PrivacySecurityScreenStyles.statusBadgeSpacing,
                    ),
                    _StatusBadge(),
                  ],
                ),
                SizedBox(
                  height: PrivacySecurityScreenStyles.statusDescriptionSpacing,
                ),
                Text(
                  PrivacySecurityScreenStyles.statusDescription,
                  style: PrivacySecurityScreenStyles.statusDescriptionStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: PrivacySecurityScreenStyles.statusBadgePadding,
      decoration: const BoxDecoration(
        color: PrivacySecurityScreenStyles.successSoftColor,
        borderRadius: PrivacySecurityScreenStyles.statusBadgeRadius,
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            PrivacySecurityScreenStyles.checkIcon,
            color: PrivacySecurityScreenStyles.successColor,
            size: PrivacySecurityScreenStyles.statusBadgeIconSize,
          ),
          SizedBox(width: PrivacySecurityScreenStyles.statusBadgeIconSpacing),
          Text(
            PrivacySecurityScreenStyles.statusBadgeLabel,
            style: PrivacySecurityScreenStyles.statusBadgeTextStyle,
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
        Text(title, style: PrivacySecurityScreenStyles.sectionTitleStyle),
        const SizedBox(
          height: PrivacySecurityScreenStyles.sectionDescriptionSpacing,
        ),
        Text(
          description,
          style: PrivacySecurityScreenStyles.sectionDescriptionStyle,
        ),
      ],
    );
  }
}

class _PrivacyTopicsCard extends StatelessWidget {
  const _PrivacyTopicsCard({required this.topics});

  final List<_PrivacyTopicData> topics;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: PrivacySecurityScreenStyles.surfaceColor,
        borderRadius: PrivacySecurityScreenStyles.cardRadius,
        border: PrivacySecurityScreenStyles.cardBorder,
        boxShadow: PrivacySecurityScreenStyles.cardShadow,
      ),
      child: Column(
        children: List<Widget>.generate(topics.length, (int index) {
          return _PrivacyTopicRow(
            topic: topics[index],
            showDivider: index != topics.length - 1,
          );
        }, growable: false),
      ),
    );
  }
}

class _PrivacyTopicRow extends StatelessWidget {
  const _PrivacyTopicRow({required this.topic, required this.showDivider});

  final _PrivacyTopicData topic;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: PrivacySecurityScreenStyles.topicRowPadding,
      decoration: showDivider
          ? const BoxDecoration(
              border: PrivacySecurityScreenStyles.topicDividerBorder,
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _PrivacyIcon(icon: topic.icon),
          const SizedBox(
            width: PrivacySecurityScreenStyles.topicContentSpacing,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  topic.title,
                  style: PrivacySecurityScreenStyles.topicTitleStyle,
                ),
                const SizedBox(
                  height: PrivacySecurityScreenStyles.topicDescriptionSpacing,
                ),
                Text(
                  topic.description,
                  style: PrivacySecurityScreenStyles.topicDescriptionStyle,
                ),
              ],
            ),
          ),
        ],
      ),
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
        final bool singleColumn =
            constraints.maxWidth <
            PrivacySecurityScreenStyles.featureSingleColumnBreakpoint;

        final double featureWidth = singleColumn
            ? constraints.maxWidth
            : (constraints.maxWidth -
                      PrivacySecurityScreenStyles.featureSpacing) /
                  2;

        return Wrap(
          spacing: PrivacySecurityScreenStyles.featureSpacing,
          runSpacing: PrivacySecurityScreenStyles.featureSpacing,
          children: features
              .map((_SecurityFeatureData feature) {
                return SizedBox(
                  width: featureWidth,
                  child: _SecurityFeatureCard(feature: feature),
                );
              })
              .toList(growable: false),
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
      constraints: const BoxConstraints(
        minHeight: PrivacySecurityScreenStyles.featureMinimumHeight,
      ),
      padding: PrivacySecurityScreenStyles.featureCardPadding,
      decoration: const BoxDecoration(
        color: PrivacySecurityScreenStyles.surfaceColor,
        borderRadius: PrivacySecurityScreenStyles.featureCardRadius,
        border: PrivacySecurityScreenStyles.cardBorder,
        boxShadow: PrivacySecurityScreenStyles.featureShadow,
      ),
      child: Row(
        children: <Widget>[
          _PrivacyIcon(icon: feature.icon),
          const SizedBox(
            width: PrivacySecurityScreenStyles.featureContentSpacing,
          ),
          Expanded(
            child: Text(
              feature.title,
              style: PrivacySecurityScreenStyles.featureTitleStyle,
            ),
          ),
          const Icon(
            PrivacySecurityScreenStyles.checkIcon,
            color: PrivacySecurityScreenStyles.successColor,
            size: PrivacySecurityScreenStyles.featureCheckSize,
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
        color: PrivacySecurityScreenStyles.surfaceColor,
        borderRadius: PrivacySecurityScreenStyles.cardRadius,
        border: PrivacySecurityScreenStyles.cardBorder,
        boxShadow: PrivacySecurityScreenStyles.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              _PrivacyIcon(icon: PrivacySecurityScreenStyles.overviewIcon),
              SizedBox(
                width: PrivacySecurityScreenStyles.overviewHeaderSpacing,
              ),
              Expanded(
                child: Text(
                  PrivacySecurityScreenStyles.overviewTitle,
                  style: PrivacySecurityScreenStyles.overviewTitleStyle,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: PrivacySecurityScreenStyles.overviewListSpacing,
          ),
          ...List<Widget>.generate(items.length, (int index) {
            return _OverviewRow(
              item: items[index],
              showBottomSpacing: index != items.length - 1,
            );
          }, growable: false),
        ],
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({required this.item, required this.showBottomSpacing});

  final _OverviewData item;
  final bool showBottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: showBottomSpacing
            ? PrivacySecurityScreenStyles.overviewRowSpacing
            : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            PrivacySecurityScreenStyles.checkIcon,
            color: PrivacySecurityScreenStyles.successColor,
            size: PrivacySecurityScreenStyles.overviewCheckSize,
          ),
          const SizedBox(
            width: PrivacySecurityScreenStyles.overviewContentSpacing,
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: '${item.title}: ',
                    style: PrivacySecurityScreenStyles.overviewEmphasisStyle,
                  ),
                  TextSpan(
                    text: item.description,
                    style: PrivacySecurityScreenStyles.overviewTextStyle,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyPromiseCard extends StatelessWidget {
  const _PrivacyPromiseCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: PrivacySecurityScreenStyles.promiseCardPadding,
      decoration: const BoxDecoration(
        gradient: PrivacySecurityScreenStyles.securityGradient,
        borderRadius: PrivacySecurityScreenStyles.cardRadius,
        boxShadow: PrivacySecurityScreenStyles.cardShadow,
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            PrivacySecurityScreenStyles.promiseIcon,
            color: PrivacySecurityScreenStyles.surfaceColor,
            size: PrivacySecurityScreenStyles.promiseIconSize,
          ),
          SizedBox(width: PrivacySecurityScreenStyles.promiseContentSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  PrivacySecurityScreenStyles.promiseTitle,
                  style: PrivacySecurityScreenStyles.promiseTitleStyle,
                ),
                SizedBox(
                  height: PrivacySecurityScreenStyles.promiseDescriptionSpacing,
                ),
                Text(
                  PrivacySecurityScreenStyles.promiseDescription,
                  style: PrivacySecurityScreenStyles.promiseBodyStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyIcon extends StatelessWidget {
  const _PrivacyIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: PrivacySecurityScreenStyles.iconContainerSize,
      height: PrivacySecurityScreenStyles.iconContainerSize,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: PrivacySecurityScreenStyles.primarySoftColor,
        borderRadius: PrivacySecurityScreenStyles.iconContainerRadius,
      ),
      child: Icon(
        icon,
        color: PrivacySecurityScreenStyles.primaryColor,
        size: PrivacySecurityScreenStyles.iconSize,
      ),
    );
  }
}

class _HeaderBrailleDecoration extends StatelessWidget {
  const _HeaderBrailleDecoration();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: PrivacySecurityScreenStyles.decorationOpacity,
      child: SizedBox(
        width: PrivacySecurityScreenStyles.decorationWidth,
        child: Wrap(
          spacing: PrivacySecurityScreenStyles.decorationDotSpacing,
          runSpacing: PrivacySecurityScreenStyles.decorationDotSpacing,
          children: List<Widget>.generate(
            PrivacySecurityScreenStyles.decorationDotCount,
            (int index) {
              return const DecoratedBox(
                decoration: BoxDecoration(
                  color: PrivacySecurityScreenStyles.surfaceColor,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: PrivacySecurityScreenStyles.decorationDotSize,
                  height: PrivacySecurityScreenStyles.decorationDotSize,
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

class _PrivacyTopicData {
  const _PrivacyTopicData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _SecurityFeatureData {
  const _SecurityFeatureData({required this.icon, required this.title});

  final IconData icon;
  final String title;
}

class _OverviewData {
  const _OverviewData({required this.title, required this.description});

  final String title;
  final String description;
}
