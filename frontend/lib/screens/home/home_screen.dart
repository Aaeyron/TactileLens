import 'package:flutter/material.dart';

import '../../models/materials/material_model.dart';
import '../../services/materials/material_service.dart';
import '../../styles/screens/home/home_screen_styles.dart';
import '../../utils/session_manager.dart';
import '../../widgets/app_header.dart';

abstract final class _HomeText {
  static const String greetingPrefix = 'Hi';
  static const String defaultUserName = 'Learner';
  static const String defaultRole = 'Student';
  static const String educatorRole = 'educator';

  static const String greetingDescription = 'Let’s make learning accessible.';

  static const String educatorGreetingDescription =
      'Let’s make teaching accessible.';

  static const String quickActionsTitle = 'Quick Actions';

  static const String scanActionTitle = 'Scan Material';
  static const String scanActionDescription =
      'Use your camera to capture printed text and mathematical equations.';

  static const String materialsActionTitle = 'Materials';
  static const String materialsActionDescription =
      'Open, organize, and review your saved accessible learning materials.';

  static const String historyActionTitle = 'Scan History';
  static const String historyActionDescription =
      'Review your previous scans, recognized content, and Braille results.';

  static const String recentActivityTitle = 'Recent Activity';
  static const String viewAllLabel = 'See all';

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
  State<HomeScreen> createState() {
    return _HomeScreenState();
  }
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

    final CurvedAnimation curve = CurvedAnimation(
      parent: _entranceController,
      curve: HomeStyles.entranceAnimationCurve,
    );

    _fadeAnimation = Tween<double>(
      begin: HomeStyles.entranceFadeBegin,
      end: HomeStyles.entranceFadeEnd,
    ).animate(curve);

    _slideAnimation = Tween<Offset>(
      begin: HomeStyles.entranceSlideBegin,
      end: Offset.zero,
    ).animate(curve);

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

    if (difference.isNegative) {
      return _HomeText.justNowLabel;
    }

    if (difference.inMinutes < 1) {
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

    if (type.contains(_HomeText.imageFileType) ||
        type.contains(_HomeText.jpgFileType) ||
        type.contains(_HomeText.jpegFileType) ||
        type.contains(_HomeText.pngFileType)) {
      return HomeStyles.imageIcon;
    }

    return HomeStyles.documentIcon;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeStyles.backgroundColor,
      body: Column(
        children: <Widget>[
          const AppHeader(),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: RefreshIndicator(
                  color: HomeStyles.primaryColor,
                  onRefresh: _loadHomeData,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: <Widget>[
                      SliverPadding(
                        padding: HomeStyles.screenPadding,
                        sliver: SliverList(
                          delegate: SliverChildListDelegate.fixed(<Widget>[
                            _buildGreeting(),
                            const SizedBox(
                              height: HomeStyles.greetingBottomSpacing,
                            ),
                            const Text(
                              _HomeText.quickActionsTitle,
                              style: HomeStyles.sectionTitleStyle,
                            ),
                            const SizedBox(
                              height: HomeStyles.quickActionsTitleSpacing,
                            ),
                            _buildQuickActions(),
                            const SizedBox(height: HomeStyles.sectionSpacing),
                            _buildRecentHeader(),
                            const SizedBox(
                              height: HomeStyles.recentHeaderSpacing,
                            ),
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
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return Container(
      width: double.infinity,
      padding: HomeStyles.greetingCardPadding,
      decoration: const BoxDecoration(
        color: HomeStyles.greetingCardBackgroundColor,
        borderRadius: HomeStyles.greetingCardRadius,
        border: HomeStyles.greetingCardBorder,
        boxShadow: HomeStyles.greetingCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${_HomeText.greetingPrefix}, $_displayName!',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: HomeStyles.greetingStyle,
          ),
          const SizedBox(height: HomeStyles.greetingSubtitleSpacing),
          Text(
            _role.toLowerCase() == _HomeText.educatorRole
                ? _HomeText.educatorGreetingDescription
                : _HomeText.greetingDescription,
            style: HomeStyles.greetingDescriptionStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: HomeStyles.surfaceColor,
        borderRadius: HomeStyles.quickActionsRadius,
        border: HomeStyles.quickActionsBorder,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          _QuickActionRow(
            icon: HomeStyles.scanIcon,
            title: _HomeText.scanActionTitle,
            description: _HomeText.scanActionDescription,
            onPressed: widget.onScanPressed,
          ),
          const Divider(
            height: HomeStyles.quickActionDividerHeight,
            thickness: HomeStyles.quickActionDividerThickness,
            indent: HomeStyles.quickActionDividerIndent,
            endIndent: HomeStyles.quickActionDividerEndIndent,
            color: HomeStyles.quickActionDividerColor,
          ),
          _QuickActionRow(
            icon: HomeStyles.materialsIcon,
            title: _HomeText.materialsActionTitle,
            description: _HomeText.materialsActionDescription,
            onPressed: widget.onMaterialsPressed,
          ),
          const Divider(
            height: HomeStyles.quickActionDividerHeight,
            thickness: HomeStyles.quickActionDividerThickness,
            indent: HomeStyles.quickActionDividerIndent,
            endIndent: HomeStyles.quickActionDividerEndIndent,
            color: HomeStyles.quickActionDividerColor,
          ),
          _QuickActionRow(
            icon: HomeStyles.historyIcon,
            title: _HomeText.historyActionTitle,
            description: _HomeText.historyActionDescription,
            onPressed: widget.onHistoryPressed,
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

    return Column(
      children: List<Widget>.generate(materials.length, (int index) {
        final MaterialModel material = materials[index];

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == materials.length - 1
                ? 0
                : HomeStyles.recentItemSpacing,
          ),
          child: _RecentActivityCard(
            material: material,
            icon: _getMaterialIcon(material),
            category: _getMaterialCategory(material),
            relativeTime: _formatRelativeTime(material.uploadDate),
            onPressed: widget.onMaterialsPressed,
          ),
        );
      }, growable: false),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: HomeStyles.quickActionRowPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: HomeStyles.quickActionIconContainerSize,
                height: HomeStyles.quickActionIconContainerSize,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: HomeStyles.quickActionIconBackgroundColor,
                  borderRadius: HomeStyles.quickActionIconRadius,
                  border: HomeStyles.quickActionIconBorder,
                ),
                child: Icon(
                  icon,
                  size: HomeStyles.quickActionIconSize,
                  color: HomeStyles.primaryColor,
                ),
              ),
              const SizedBox(width: HomeStyles.quickActionContentSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: HomeStyles.quickActionTitleStyle),
                    const SizedBox(
                      height: HomeStyles.quickActionDescriptionSpacing,
                    ),
                    Text(
                      description,
                      style: HomeStyles.quickActionDescriptionStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: HomeStyles.quickActionArrowSpacing),
              Container(
                width: HomeStyles.quickActionArrowContainerSize,
                height: HomeStyles.quickActionArrowContainerSize,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: HomeStyles.quickActionArrowBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  HomeStyles.forwardIcon,
                  size: HomeStyles.quickActionArrowIconSize,
                  color: HomeStyles.primaryColor,
                ),
              ),
            ],
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
    required this.onPressed,
  });

  final MaterialModel material;
  final IconData icon;
  final String category;
  final String relativeTime;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final String title = material.title.trim().isEmpty
        ? material.fileName
        : material.title.trim();

    return Container(
      decoration: const BoxDecoration(
        color: HomeStyles.surfaceColor,
        borderRadius: HomeStyles.recentCardRadius,
        border: HomeStyles.cardBorder,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: HomeStyles.recentCardRadius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: HomeStyles.recentCardRadius,
          child: Padding(
            padding: HomeStyles.recentCardPadding,
            child: Row(
              children: <Widget>[
                Container(
                  width: HomeStyles.thumbnailSize,
                  height: HomeStyles.thumbnailSize,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: HomeStyles.thumbnailBackgroundColor,
                    borderRadius: HomeStyles.thumbnailRadius,
                    border: HomeStyles.thumbnailBorder,
                  ),
                  child: Icon(
                    icon,
                    color: HomeStyles.primaryColor,
                    size: HomeStyles.thumbnailIconSize,
                  ),
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
                    ],
                  ),
                ),
                const SizedBox(width: HomeStyles.recentContentSpacing),
                Text(relativeTime, style: HomeStyles.relativeTimeStyle),
              ],
            ),
          ),
        ),
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
        borderRadius: HomeStyles.recentCardRadius,
        border: HomeStyles.cardBorder,
      ),
      child: Column(
        children: <Widget>[
          if (showProgress)
            const CircularProgressIndicator(color: HomeStyles.primaryColor)
          else
            Icon(
              icon,
              size: HomeStyles.stateIconSize,
              color: HomeStyles.primaryColor,
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
            FilledButton(onPressed: onActionPressed, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
