import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/materials/material_model.dart';
import '../../services/materials/material_service.dart';
import '../../styles/screens/home/home_screen_styles.dart';
import '../../utils/session_manager.dart';

abstract final class _HomeText {
  static const String appName = 'TactileLens';
  static const String notificationTooltip = 'Notifications';
  static const String greetingPrefix = 'Hi';
  static const String defaultUserName = 'Learner';
  static const String defaultRole = 'Student';
  static const String educatorRole = 'educator';

  static const String greetingDescription =
      'Make every lesson more accessible.';

  static const String educatorGreetingDescription =
      'Make every lesson more accessible.';

  static const String quickScanTitle = 'Quick Scan';
  static const String quickScanDescription =
      'Capture a document and generate accessible text and Braille output.';
  static const String startScanningLabel = 'Start Scanning';

  static const String materialsActionTitle = 'Materials';
  static const String materialsActionDescription =
      'View and organize saved learning materials.';

  static const String historyActionTitle = 'History';
  static const String historyActionDescription =
      'Review previous scans and translations.';

  static const String recentActivityTitle = 'Recent Activity';
  static const String viewAllLabel = 'View all';

  static const String mathNemethLabel = 'Math • Nemeth';
  static const String textUebLabel = 'Text • UEB';

  static const String loadingTitle = 'Loading activity';
  static const String loadingDescription =
      'Your recent materials are being prepared.';

  static const String errorTitle = 'Activity unavailable';
  static const String loadFailureMessage =
      'Unable to load your recent activity.';

  static const String retryLabel = 'Try Again';

  static const String emptyTitle = 'No recent activity';
  static const String emptyDescription =
      'Scan your first learning material to see it here.';

  static const String scanNowLabel = 'Scan Now';

  static const String justNowLabel = 'Now';
  static const String minuteSuffix = 'm ago';
  static const String hourSuffix = 'h ago';
  static const String daySuffix = 'd ago';

  static const String pdfFileType = 'pdf';
  static const String imageFileType = 'image';
  static const String jpgFileType = 'jpg';
  static const String jpegFileType = 'jpeg';
  static const String pngFileType = 'png';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onScanPressed,
    required this.onMaterialsPressed,
    required this.onHistoryPressed,
  });

  final VoidCallback onScanPressed;
  final VoidCallback onMaterialsPressed;
  final VoidCallback onHistoryPressed;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final MaterialService _materialService = MaterialService();

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  List<MaterialModel> _materials = <MaterialModel>[];

  String _displayName = _HomeText.defaultUserName;
  String _role = _HomeText.defaultRole;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _initializeEntranceAnimation();
    _loadHomeData();
  }

  void _initializeEntranceAnimation() {
    _entranceController = AnimationController(
      vsync: this,
      duration: HomeStyles.entranceAnimationDuration,
    );

    final CurvedAnimation entranceCurve = CurvedAnimation(
      parent: _entranceController,
      curve: HomeStyles.entranceAnimationCurve,
    );

    _fadeAnimation = Tween<double>(
      begin: HomeStyles.entranceFadeBegin,
      end: HomeStyles.entranceFadeEnd,
    ).animate(entranceCurve);

    _slideAnimation = Tween<Offset>(
      begin: HomeStyles.entranceSlideBegin,
      end: Offset.zero,
    ).animate(entranceCurve);

    Future<void>.delayed(HomeStyles.entranceAnimationDelay, () {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _materialService.dispose();
    super.dispose();
  }

  Future<void> _loadHomeData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final bool isGuest = await SessionManager.isGuest();

      final String? storedName = isGuest
          ? await SessionManager.getGuestNickname()
          : await SessionManager.getFirstName();

      final String? storedRole = await SessionManager.getRole();

      final List<MaterialModel> materials = await _materialService
          .getMaterials();

      if (!mounted) {
        return;
      }

      setState(() {
        _displayName = _normalizeValue(storedName, _HomeText.defaultUserName);

        _role = _normalizeValue(storedRole, _HomeText.defaultRole);

        _materials = materials;
        _isLoading = false;
      });
    } on MaterialServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = _HomeText.loadFailureMessage;
      });
    }
  }

  String _normalizeValue(String? value, String fallback) {
    final String normalizedValue = value?.trim() ?? '';

    return normalizedValue.isEmpty ? fallback : normalizedValue;
  }

  List<MaterialModel> get _recentMaterials {
    final List<MaterialModel> materials = List<MaterialModel>.from(_materials);

    materials.sort((MaterialModel first, MaterialModel second) {
      return second.uploadDate.compareTo(first.uploadDate);
    });

    return materials
        .take(HomeStyles.maximumRecentMaterials)
        .toList(growable: false);
  }

  String _formatRelativeTime(DateTime value) {
    final DateTime date = value.toLocal();
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(date);

    if (difference.isNegative || difference.inMinutes < 1) {
      return _HomeText.justNowLabel;
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}${_HomeText.minuteSuffix}';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}${_HomeText.hourSuffix}';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}${_HomeText.daySuffix}';
    }

    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  String _getMaterialCategory(MaterialModel material) {
    final String content = material.recognizedContent.toLowerCase();

    final bool containsMath =
        content.contains(r'\frac') ||
        content.contains(r'\sqrt') ||
        content.contains('=') ||
        content.contains('^');

    return containsMath ? _HomeText.mathNemethLabel : _HomeText.textUebLabel;
  }

  IconData _getMaterialIcon(MaterialModel material) {
    final String type = material.fileType.toLowerCase();

    if (type.contains(_HomeText.pdfFileType)) {
      return HomeStyles.pdfIcon;
    }

    if (_isImageMaterial(material)) {
      return HomeStyles.imageIcon;
    }

    return HomeStyles.documentIcon;
  }

  bool _isImageMaterial(MaterialModel material) {
    final String type = material.fileType.toLowerCase();

    return type.contains(_HomeText.imageFileType) ||
        type.contains(_HomeText.jpgFileType) ||
        type.contains(_HomeText.jpegFileType) ||
        type.contains(_HomeText.pngFileType);
  }

  bool _hasLocalPreview(MaterialModel material) {
    final String filePath = material.filePath.trim();

    if (!_isImageMaterial(material) || filePath.isEmpty) {
      return false;
    }

    return File(filePath).existsSync();
  }

  String _greetingDescription() {
    if (_role.toLowerCase() == _HomeText.educatorRole) {
      return _HomeText.educatorGreetingDescription;
    }

    return _HomeText.greetingDescription;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: HomeStyles.backgroundColor,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: RefreshIndicator(
              color: HomeStyles.primaryColor,
              backgroundColor: HomeStyles.surfaceColor,
              onRefresh: _loadHomeData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: <Widget>[
                  SliverToBoxAdapter(child: _buildHeaderSection(context)),
                  SliverPadding(
                    padding: HomeStyles.contentPadding,
                    sliver: SliverList(
                      delegate: SliverChildListDelegate.fixed(<Widget>[
                        _buildSecondaryActions(),
                        const SizedBox(height: HomeStyles.sectionSpacing),
                        _buildRecentHeader(),
                        const SizedBox(height: HomeStyles.recentHeaderSpacing),
                        _buildRecentActivity(),
                        const SizedBox(height: HomeStyles.bottomSpacing),
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

  Widget _buildHeaderSection(BuildContext context) {
    final double statusBarHeight = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: statusBarHeight + HomeStyles.headerSectionHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: double.infinity,
            height: statusBarHeight + HomeStyles.blueHeaderHeight,
            padding: EdgeInsets.fromLTRB(
              HomeStyles.headerHorizontalPadding,
              statusBarHeight + HomeStyles.headerTopPadding,
              HomeStyles.headerHorizontalPadding,
              HomeStyles.headerBottomPadding,
            ),
            decoration: const BoxDecoration(
              gradient: HomeStyles.greetingGradient,
              borderRadius: HomeStyles.blueHeaderRadius,
            ),
            child: Stack(
              children: <Widget>[
                const Positioned(
                  right: HomeStyles.headerBrailleRight,
                  bottom: HomeStyles.headerBrailleBottom,
                  child: _BrailleDecoration(),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Expanded(
                          child: Text(
                            _HomeText.appName,
                            style: HomeStyles.appNameStyle,
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: _HomeText.notificationTooltip,
                          child: InkResponse(
                            onTap: () {},
                            radius: HomeStyles.notificationTapRadius,
                            child: const SizedBox(
                              width: HomeStyles.notificationButtonSize,
                              height: HomeStyles.notificationButtonSize,
                              child: Icon(
                                HomeStyles.notificationIcon,
                                color: HomeStyles.surfaceColor,
                                size: HomeStyles.notificationIconSize,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '${_HomeText.greetingPrefix}, $_displayName!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HomeStyles.greetingStyle,
                    ),
                    const SizedBox(height: HomeStyles.greetingSubtitleSpacing),
                    Text(
                      _greetingDescription(),
                      style: HomeStyles.greetingDescriptionStyle,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: HomeStyles.headerHorizontalPadding,
            right: HomeStyles.headerHorizontalPadding,
            top: statusBarHeight + HomeStyles.quickScanCardTop,
            child: _buildQuickScanCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickScanCard() {
    return Container(
      width: double.infinity,
      padding: HomeStyles.quickScanCardPadding,
      decoration: const BoxDecoration(
        color: HomeStyles.surfaceColor,
        borderRadius: HomeStyles.quickScanCardRadius,
        border: HomeStyles.cardBorder,
        boxShadow: HomeStyles.cardShadow,
      ),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      _HomeText.quickScanTitle,
                      style: HomeStyles.quickScanTitleStyle,
                    ),
                    const SizedBox(
                      height: HomeStyles.quickScanDescriptionSpacing,
                    ),
                    const Text(
                      _HomeText.quickScanDescription,
                      style: HomeStyles.quickScanDescriptionStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: HomeStyles.quickScanIconSpacing),
              Container(
                width: HomeStyles.quickScanIconContainerSize,
                height: HomeStyles.quickScanIconContainerSize,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: HomeStyles.quickScanIconBackgroundColor,
                  borderRadius: HomeStyles.quickScanIconRadius,
                ),
                child: const Icon(
                  HomeStyles.scanIcon,
                  color: HomeStyles.primaryColor,
                  size: HomeStyles.quickScanIconSize,
                ),
              ),
            ],
          ),
          const SizedBox(height: HomeStyles.quickScanButtonSpacing),
          SizedBox(
            width: double.infinity,
            height: HomeStyles.quickScanButtonHeight,
            child: FilledButton.icon(
              onPressed: widget.onScanPressed,
              style: HomeStyles.quickScanButtonStyle,
              icon: const Icon(
                HomeStyles.cameraIcon,
                size: HomeStyles.quickScanButtonIconSize,
              ),
              label: const Text(_HomeText.startScanningLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryActions() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: _CompactActionCard(
              icon: HomeStyles.materialsIcon,
              title: _HomeText.materialsActionTitle,
              description: _HomeText.materialsActionDescription,
              onPressed: widget.onMaterialsPressed,
            ),
          ),
          const SizedBox(width: HomeStyles.secondaryActionSpacing),
          Expanded(
            child: _CompactActionCard(
              icon: HomeStyles.historyIcon,
              title: _HomeText.historyActionTitle,
              description: _HomeText.historyActionDescription,
              onPressed: widget.onHistoryPressed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentHeader() {
    return Row(
      children: <Widget>[
        const Expanded(
          child: Text(
            _HomeText.recentActivityTitle,
            style: HomeStyles.sectionTitleStyle,
          ),
        ),
        TextButton(
          onPressed: widget.onHistoryPressed,
          style: HomeStyles.viewAllButtonStyle,
          child: const Text(_HomeText.viewAllLabel),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    if (_isLoading) {
      return const _StateCard(
        showProgress: true,
        icon: HomeStyles.historyIcon,
        title: _HomeText.loadingTitle,
        description: _HomeText.loadingDescription,
      );
    }

    if (_errorMessage != null) {
      return _StateCard(
        icon: HomeStyles.errorIcon,
        title: _HomeText.errorTitle,
        description: _errorMessage!,
        actionLabel: _HomeText.retryLabel,
        onActionPressed: _loadHomeData,
      );
    }

    final List<MaterialModel> materials = _recentMaterials;

    if (materials.isEmpty) {
      return _StateCard(
        icon: HomeStyles.emptyIcon,
        title: _HomeText.emptyTitle,
        description: _HomeText.emptyDescription,
        actionLabel: _HomeText.scanNowLabel,
        onActionPressed: widget.onScanPressed,
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: HomeStyles.surfaceColor,
        borderRadius: HomeStyles.recentListRadius,
        border: HomeStyles.cardBorder,
        boxShadow: HomeStyles.subtleCardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List<Widget>.generate(materials.length, (int index) {
          final MaterialModel material = materials[index];

          return Column(
            children: <Widget>[
              _RecentActivityCard(
                material: material,
                icon: _getMaterialIcon(material),
                category: _getMaterialCategory(material),
                relativeTime: _formatRelativeTime(material.uploadDate),
                showImagePreview: _hasLocalPreview(material),
                onPressed: widget.onMaterialsPressed,
              ),
              if (index < materials.length - 1)
                const Divider(
                  height: HomeStyles.recentDividerHeight,
                  thickness: HomeStyles.recentDividerThickness,
                  indent: HomeStyles.recentDividerIndent,
                  color: HomeStyles.dividerColor,
                ),
            ],
          );
        }, growable: false),
      ),
    );
  }
}

class _BrailleDecoration extends StatelessWidget {
  const _BrailleDecoration();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: HomeStyles.heroDecorationOpacity,
      child: SizedBox(
        width: HomeStyles.heroDecorationWidth,
        child: Wrap(
          spacing: HomeStyles.heroDotSpacing,
          runSpacing: HomeStyles.heroDotSpacing,
          children: List<Widget>.generate(
            HomeStyles.heroDotCount,
            (_) => Container(
              width: HomeStyles.heroDotSize,
              height: HomeStyles.heroDotSize,
              decoration: const BoxDecoration(
                color: HomeStyles.surfaceColor,
                shape: BoxShape.circle,
              ),
            ),
            growable: false,
          ),
        ),
      ),
    );
  }
}

class _CompactActionCard extends StatelessWidget {
  const _CompactActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: HomeStyles.surfaceColor,
        borderRadius: HomeStyles.secondaryActionRadius,
        border: HomeStyles.cardBorder,
        boxShadow: HomeStyles.subtleCardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: HomeStyles.secondaryActionRadius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: HomeStyles.secondaryActionRadius,
          child: Padding(
            padding: HomeStyles.secondaryActionPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: HomeStyles.secondaryActionIconContainerSize,
                      height: HomeStyles.secondaryActionIconContainerSize,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: HomeStyles.secondaryActionIconBackgroundColor,
                        borderRadius: HomeStyles.secondaryActionIconRadius,
                      ),
                      child: Icon(
                        icon,
                        size: HomeStyles.secondaryActionIconSize,
                        color: HomeStyles.primaryColor,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      HomeStyles.forwardIcon,
                      size: HomeStyles.secondaryActionArrowSize,
                      color: HomeStyles.mutedColor,
                    ),
                  ],
                ),
                const SizedBox(height: HomeStyles.secondaryActionTitleSpacing),
                Text(title, style: HomeStyles.secondaryActionTitleStyle),
                const SizedBox(
                  height: HomeStyles.secondaryActionDescriptionSpacing,
                ),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: HomeStyles.secondaryActionDescriptionStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({
    required this.material,
    required this.icon,
    required this.category,
    required this.relativeTime,
    required this.showImagePreview,
    required this.onPressed,
  });

  final MaterialModel material;
  final IconData icon;
  final String category;
  final String relativeTime;
  final bool showImagePreview;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final String title = material.title.trim().isEmpty
        ? material.fileName
        : material.title.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: HomeStyles.recentCardPadding,
          child: Row(
            children: <Widget>[
              _MaterialThumbnail(
                material: material,
                fallbackIcon: icon,
                showImagePreview: showImagePreview,
              ),
              const SizedBox(width: HomeStyles.recentContentSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HomeStyles.recentTitleStyle,
                    ),
                    const SizedBox(height: HomeStyles.recentMetadataSpacing),
                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HomeStyles.recentMetadataStyle,
                    ),
                    const SizedBox(height: HomeStyles.recentDateSpacing),
                    Text(relativeTime, style: HomeStyles.relativeTimeStyle),
                  ],
                ),
              ),
              const SizedBox(width: HomeStyles.recentTrailingSpacing),
              const Icon(
                HomeStyles.forwardIcon,
                color: HomeStyles.recentArrowColor,
                size: HomeStyles.recentArrowSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialThumbnail extends StatelessWidget {
  const _MaterialThumbnail({
    required this.material,
    required this.fallbackIcon,
    required this.showImagePreview,
  });

  final MaterialModel material;
  final IconData fallbackIcon;
  final bool showImagePreview;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: HomeStyles.thumbnailWidth,
      height: HomeStyles.thumbnailHeight,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: HomeStyles.thumbnailBackgroundColor,
        borderRadius: HomeStyles.thumbnailRadius,
        border: HomeStyles.thumbnailBorder,
      ),
      child: showImagePreview
          ? Image.file(
              File(material.filePath),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stackTrace) {
                    return _ThumbnailFallback(icon: fallbackIcon);
                  },
            )
          : _ThumbnailFallback(icon: fallbackIcon),
    );
  }
}

class _ThumbnailFallback extends StatelessWidget {
  const _ThumbnailFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        icon,
        color: HomeStyles.primaryColor,
        size: HomeStyles.thumbnailIconSize,
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onActionPressed,
    this.showProgress = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: HomeStyles.stateCardPadding,
      decoration: const BoxDecoration(
        color: HomeStyles.surfaceColor,
        borderRadius: HomeStyles.recentListRadius,
        border: HomeStyles.cardBorder,
        boxShadow: HomeStyles.subtleCardShadow,
      ),
      child: Column(
        children: <Widget>[
          if (showProgress)
            const SizedBox(
              width: HomeStyles.stateProgressSize,
              height: HomeStyles.stateProgressSize,
              child: CircularProgressIndicator(
                color: HomeStyles.primaryColor,
                strokeWidth: HomeStyles.stateProgressStrokeWidth,
              ),
            )
          else
            Container(
              width: HomeStyles.stateIconContainerSize,
              height: HomeStyles.stateIconContainerSize,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: HomeStyles.secondaryActionIconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: HomeStyles.stateIconSize,
                color: HomeStyles.primaryColor,
              ),
            ),
          const SizedBox(height: HomeStyles.stateContentSpacing),
          Text(
            title,
            textAlign: TextAlign.center,
            style: HomeStyles.stateTitleStyle,
          ),
          const SizedBox(height: HomeStyles.stateDescriptionSpacing),
          Text(
            description,
            textAlign: TextAlign.center,
            style: HomeStyles.stateDescriptionStyle,
          ),
          if (actionLabel != null && onActionPressed != null) ...<Widget>[
            const SizedBox(height: HomeStyles.stateActionSpacing),
            FilledButton(
              onPressed: onActionPressed,
              style: HomeStyles.stateActionButtonStyle,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
