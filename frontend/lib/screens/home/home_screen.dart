import 'package:flutter/material.dart';

import '../../models/materials/material_model.dart';
import '../../services/materials/material_service.dart';
import '../../styles/screens/home/home_screen_styles.dart';
import '../../utils/session_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onScanPressed,
    required this.onMaterialsPressed,
  });

  final VoidCallback onScanPressed;
  final VoidCallback onMaterialsPressed;

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

  String _displayName = HomeStyles.defaultUserName;
  String _role = HomeStyles.defaultRole;

  bool _isGuest = false;
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

      if (!mounted) {
        return;
      }

      setState(() {
        _isGuest = isGuest;
        _displayName = _normalizeDisplayName(storedName);
        _role = _normalizeRole(storedRole);
      });

      final List<MaterialModel> materials = await _materialService
          .getMaterials();

      if (!mounted) {
        return;
      }

      setState(() {
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
        _errorMessage = HomeStyles.loadFailureMessage;
      });
    }
  }

  String _normalizeDisplayName(String? value) {
    final String normalizedValue = value?.trim() ?? '';

    return normalizedValue.isEmpty
        ? HomeStyles.defaultUserName
        : normalizedValue;
  }

  String _normalizeRole(String? value) {
    final String normalizedValue = value?.trim() ?? '';

    if (normalizedValue.isEmpty) {
      return HomeStyles.defaultRole;
    }

    return '${normalizedValue[0].toUpperCase()}'
        '${normalizedValue.substring(1).toLowerCase()}';
  }

  String get _initial {
    final String normalizedName = _displayName.trim();

    if (normalizedName.isEmpty) {
      return HomeStyles.defaultInitial;
    }

    return normalizedName[0].toUpperCase();
  }

  List<MaterialModel> get _recentMaterials {
    return _materials
        .take(HomeStyles.maximumRecentMaterials)
        .toList(growable: false);
  }

  String _formatFileSize(int sizeInBytes) {
    if (sizeInBytes < HomeStyles.bytesPerKilobyte) {
      return '$sizeInBytes ${HomeStyles.byteLabel}';
    }

    final double sizeInKilobytes = sizeInBytes / HomeStyles.bytesPerKilobyte;

    if (sizeInKilobytes < HomeStyles.bytesPerKilobyte) {
      return '${sizeInKilobytes.toStringAsFixed(1)} '
          '${HomeStyles.kilobyteLabel}';
    }

    final double sizeInMegabytes =
        sizeInKilobytes / HomeStyles.bytesPerKilobyte;

    return '${sizeInMegabytes.toStringAsFixed(1)} '
        '${HomeStyles.megabyteLabel}';
  }

  String _formatDate(BuildContext context, DateTime date) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );

    final DateTime now = DateTime.now();

    final DateTime currentDate = DateTime(now.year, now.month, now.day);

    final DateTime materialDate = DateTime(date.year, date.month, date.day);

    final int difference = currentDate.difference(materialDate).inDays;

    if (difference == 0) {
      return HomeStyles.todayLabel;
    }

    if (difference == 1) {
      return HomeStyles.yesterdayLabel;
    }

    return localizations.formatMediumDate(date);
  }

  IconData _getMaterialIcon(MaterialModel material) {
    final String type = material.fileType.toLowerCase();

    if (type.contains(HomeStyles.pdfFileType)) {
      return HomeStyles.pdfIcon;
    }

    if (type.contains(HomeStyles.imageFileType) ||
        type.contains(HomeStyles.jpgFileType) ||
        type.contains(HomeStyles.jpegFileType) ||
        type.contains(HomeStyles.pngFileType)) {
      return HomeStyles.imageIcon;
    }

    return HomeStyles.documentIcon;
  }

  Color _getMaterialAccent(MaterialModel material) {
    final String type = material.fileType.toLowerCase();

    if (type.contains(HomeStyles.pdfFileType)) {
      return HomeStyles.pdfColor;
    }

    if (type.contains(HomeStyles.imageFileType) ||
        type.contains(HomeStyles.jpgFileType) ||
        type.contains(HomeStyles.jpegFileType) ||
        type.contains(HomeStyles.pngFileType)) {
      return HomeStyles.imageColor;
    }

    return HomeStyles.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeStyles.backgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            bottom: false,
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
                        _buildBrandHeader(),
                        const SizedBox(height: HomeStyles.greetingTopSpacing),
                        _buildWelcomeSection(),
                        const SizedBox(height: HomeStyles.sectionSpacing),
                        _buildProfileCard(),
                        const SizedBox(height: HomeStyles.sectionSpacing),
                        const Text(
                          HomeStyles.quickActionsTitle,
                          style: HomeStyles.sectionTitleStyle,
                        ),
                        const SizedBox(height: HomeStyles.sectionTitleSpacing),
                        _buildQuickActions(),
                        const SizedBox(height: HomeStyles.sectionSpacing),
                        _buildRecentHeader(),
                        const SizedBox(height: HomeStyles.sectionTitleSpacing),
                        _buildRecentMaterials(),
                        const SizedBox(height: HomeStyles.sectionSpacing),
                        _buildEncouragementCard(),
                        const SizedBox(height: HomeStyles.bottomContentSpacing),
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

  Widget _buildBrandHeader() {
    return Row(
      children: <Widget>[
        ClipRRect(
          borderRadius: HomeStyles.logoRadius,
          child: Image.asset(
            HomeStyles.logoAsset,
            width: HomeStyles.logoSize,
            height: HomeStyles.logoSize,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: HomeStyles.logoTextSpacing),
        const Expanded(
          child: Text(HomeStyles.appName, style: HomeStyles.appNameStyle),
        ),
        Container(
          width: HomeStyles.statusButtonSize,
          height: HomeStyles.statusButtonSize,
          decoration: const BoxDecoration(
            color: HomeStyles.surfaceColor,
            shape: BoxShape.circle,
            border: HomeStyles.smallContainerBorder,
            boxShadow: HomeStyles.smallContainerShadow,
          ),
          child: Icon(
            _isGuest ? HomeStyles.offlineIcon : HomeStyles.syncedIcon,
            size: HomeStyles.statusIconSize,
            color: HomeStyles.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          flex: HomeStyles.welcomeTextFlex,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${HomeStyles.greetingPrefix}, $_displayName!',
                style: HomeStyles.greetingStyle,
              ),
              const SizedBox(height: HomeStyles.greetingDescriptionSpacing),
              Text(
                _isGuest
                    ? HomeStyles.guestWelcomeDescription
                    : HomeStyles.welcomeDescription,
                style: HomeStyles.welcomeDescriptionStyle,
              ),
            ],
          ),
        ),
        const SizedBox(width: HomeStyles.welcomeContentSpacing),
        Expanded(
          flex: HomeStyles.welcomeIllustrationFlex,
          child: Container(
            height: HomeStyles.illustrationHeight,
            decoration: const BoxDecoration(
              color: HomeStyles.illustrationBackgroundColor,
              borderRadius: HomeStyles.illustrationRadius,
              border: HomeStyles.cardBorder,
              boxShadow: HomeStyles.cardShadow,
            ),
            child: const Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Icon(
                  HomeStyles.illustrationBookIcon,
                  size: HomeStyles.illustrationBookIconSize,
                  color: HomeStyles.illustrationBookColor,
                ),
                Positioned(
                  right: HomeStyles.illustrationSearchRight,
                  bottom: HomeStyles.illustrationSearchBottom,
                  child: Icon(
                    HomeStyles.illustrationSearchIcon,
                    size: HomeStyles.illustrationSearchIconSize,
                    color: HomeStyles.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: HomeStyles.profileCardPadding,
      decoration: const BoxDecoration(
        color: HomeStyles.surfaceColor,
        borderRadius: HomeStyles.cardRadius,
        border: HomeStyles.cardBorder,
        boxShadow: HomeStyles.cardShadow,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: HomeStyles.avatarSize,
            height: HomeStyles.avatarSize,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: HomeStyles.avatarBackgroundColor,
              shape: BoxShape.circle,
              border: HomeStyles.smallContainerBorder,
              boxShadow: HomeStyles.smallContainerShadow,
            ),
            child: Text(_initial, style: HomeStyles.avatarTextStyle),
          ),
          const SizedBox(width: HomeStyles.profileContentSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HomeStyles.profileNameStyle,
                ),
                const SizedBox(height: HomeStyles.profileRoleSpacing),
                Text(
                  _isGuest ? '${HomeStyles.offlineRolePrefix} · $_role' : _role,
                  style: HomeStyles.profileRoleStyle,
                ),
              ],
            ),
          ),
          const Icon(
            HomeStyles.profileStatusIcon,
            color: HomeStyles.primaryColor,
            size: HomeStyles.profileStatusIconSize,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final List<Widget> actionCards = <Widget>[
          _HomeActionCard(
            icon: HomeStyles.scanIcon,
            iconColor: HomeStyles.primaryColor,
            iconBackgroundColor: HomeStyles.scanIconBackgroundColor,
            title: HomeStyles.scanTitle,
            description: HomeStyles.scanDescription,
            onPressed: widget.onScanPressed,
          ),
          _HomeActionCard(
            icon: HomeStyles.uploadIcon,
            iconColor: HomeStyles.uploadColor,
            iconBackgroundColor: HomeStyles.uploadIconBackgroundColor,
            title: HomeStyles.uploadTitle,
            description: HomeStyles.uploadDescription,
            onPressed: widget.onScanPressed,
          ),
          _HomeActionCard(
            icon: HomeStyles.materialsIcon,
            iconColor: HomeStyles.materialsColor,
            iconBackgroundColor: HomeStyles.materialsIconBackgroundColor,
            title: HomeStyles.materialsTitle,
            description: HomeStyles.materialsDescription,
            onPressed: widget.onMaterialsPressed,
          ),
        ];

        if (constraints.maxWidth >= HomeStyles.wideQuickActionsBreakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List<Widget>.generate(actionCards.length, (int index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == actionCards.length - 1
                        ? HomeStyles.zero
                        : HomeStyles.quickActionSpacing,
                  ),
                  child: actionCards[index],
                ),
              );
            }),
          );
        }

        return SizedBox(
          height: HomeStyles.quickActionCardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: actionCards.length,
            separatorBuilder: (BuildContext context, int index) {
              return const SizedBox(width: HomeStyles.quickActionSpacing);
            },
            itemBuilder: (BuildContext context, int index) {
              return SizedBox(
                width: HomeStyles.compactQuickActionWidth,
                child: actionCards[index],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRecentHeader() {
    return Row(
      children: <Widget>[
        const Expanded(
          child: Text(
            HomeStyles.recentMaterialsTitle,
            style: HomeStyles.sectionTitleStyle,
          ),
        ),
        TextButton.icon(
          onPressed: widget.onMaterialsPressed,
          style: HomeStyles.viewAllButtonStyle,
          label: const Text(HomeStyles.viewAllLabel),
          icon: const Icon(
            HomeStyles.forwardIcon,
            size: HomeStyles.viewAllIconSize,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentMaterials() {
    if (_isLoading) {
      return const _HomeStateCard(
        showProgress: true,
        icon: HomeStyles.materialsIcon,
        title: HomeStyles.loadingMaterialsTitle,
        description: HomeStyles.loadingMaterialsDescription,
      );
    }

    if (_errorMessage != null) {
      return _HomeStateCard(
        icon: HomeStyles.errorIcon,
        title: HomeStyles.materialsErrorTitle,
        description: _errorMessage!,
        actionLabel: HomeStyles.retryLabel,
        onActionPressed: _loadHomeData,
      );
    }

    final List<MaterialModel> recentMaterials = _recentMaterials;

    if (recentMaterials.isEmpty) {
      return _HomeStateCard(
        icon: HomeStyles.emptyMaterialsIcon,
        title: HomeStyles.emptyMaterialsTitle,
        description: HomeStyles.emptyMaterialsDescription,
        actionLabel: HomeStyles.scanNowLabel,
        onActionPressed: widget.onScanPressed,
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: HomeStyles.surfaceColor,
        borderRadius: HomeStyles.cardRadius,
        border: HomeStyles.cardBorder,
        boxShadow: HomeStyles.cardShadow,
      ),
      child: Column(
        children: List<Widget>.generate(recentMaterials.length, (int index) {
          final MaterialModel material = recentMaterials[index];

          return Column(
            children: <Widget>[
              _RecentMaterialTile(
                material: material,
                icon: _getMaterialIcon(material),
                accentColor: _getMaterialAccent(material),
                fileSize: _formatFileSize(material.fileSize),
                date: _formatDate(context, material.uploadDate),
                onPressed: widget.onMaterialsPressed,
              ),
              if (index != recentMaterials.length - 1)
                const Divider(
                  height: HomeStyles.dividerHeight,
                  indent: HomeStyles.recentDividerIndent,
                  color: HomeStyles.dividerColor,
                ),
            ],
          );
        }, growable: false),
      ),
    );
  }

  Widget _buildEncouragementCard() {
    return Container(
      width: double.infinity,
      padding: HomeStyles.encouragementPadding,
      decoration: const BoxDecoration(
        color: HomeStyles.encouragementBackgroundColor,
        borderRadius: HomeStyles.cardRadius,
        border: HomeStyles.encouragementBorder,
      ),
      child: const Row(
        children: <Widget>[
          Icon(
            HomeStyles.encouragementIcon,
            size: HomeStyles.encouragementIconSize,
            color: HomeStyles.primaryColor,
          ),
          SizedBox(width: HomeStyles.encouragementContentSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  HomeStyles.encouragementTitle,
                  style: HomeStyles.encouragementTitleStyle,
                ),
                SizedBox(height: HomeStyles.encouragementDescriptionSpacing),
                Text(
                  HomeStyles.encouragementDescription,
                  style: HomeStyles.encouragementDescriptionStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.title,
    required this.description,
    required this.onPressed,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String title;
  final String description;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomeStyles.surfaceColor,
      borderRadius: HomeStyles.cardRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: HomeStyles.cardRadius,
        child: Container(
          height: HomeStyles.quickActionCardHeight,
          padding: HomeStyles.quickActionPadding,
          decoration: const BoxDecoration(
            borderRadius: HomeStyles.cardRadius,
            border: HomeStyles.cardBorder,
            boxShadow: HomeStyles.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: HomeStyles.actionIconContainerSize,
                height: HomeStyles.actionIconContainerSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  shape: BoxShape.circle,
                  border: HomeStyles.smallContainerBorder,
                  boxShadow: HomeStyles.smallContainerShadow,
                ),
                child: Icon(
                  icon,
                  size: HomeStyles.actionIconSize,
                  color: iconColor,
                ),
              ),
              const Spacer(),
              Text(title, style: HomeStyles.actionTitleStyle),
              const SizedBox(height: HomeStyles.actionDescriptionSpacing),
              Text(
                description,
                maxLines: HomeStyles.actionDescriptionMaximumLines,
                overflow: TextOverflow.ellipsis,
                style: HomeStyles.actionDescriptionStyle,
              ),
              const SizedBox(height: HomeStyles.actionArrowSpacing),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  HomeStyles.forwardIcon,
                  size: HomeStyles.actionArrowSize,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentMaterialTile extends StatelessWidget {
  const _RecentMaterialTile({
    required this.material,
    required this.icon,
    required this.accentColor,
    required this.fileSize,
    required this.date,
    required this.onPressed,
  });

  final MaterialModel material;
  final IconData icon;
  final Color accentColor;
  final String fileSize;
  final String date;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: HomeStyles.cardRadius,
      child: Padding(
        padding: HomeStyles.recentMaterialPadding,
        child: Row(
          children: <Widget>[
            Container(
              width: HomeStyles.recentFileIconContainerSize,
              height: HomeStyles.recentFileIconContainerSize,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: HomeStyles.surfaceColor,
                borderRadius: HomeStyles.fileIconRadius,
                border: HomeStyles.smallContainerBorder,
                boxShadow: HomeStyles.smallContainerShadow,
              ),
              child: Icon(
                icon,
                size: HomeStyles.recentFileIconSize,
                color: accentColor,
              ),
            ),
            const SizedBox(width: HomeStyles.recentMaterialContentSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    material.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HomeStyles.recentMaterialTitleStyle,
                  ),
                  const SizedBox(height: HomeStyles.recentMetadataSpacing),
                  Text(
                    '${material.subject}'
                    '${HomeStyles.metadataSeparator}'
                    '$fileSize'
                    '${HomeStyles.metadataSeparator}'
                    '$date',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HomeStyles.recentMetadataStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: HomeStyles.recentMaterialContentSpacing),
            const Icon(
              HomeStyles.viewMaterialIcon,
              size: HomeStyles.viewMaterialIconSize,
              color: HomeStyles.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeStateCard extends StatelessWidget {
  const _HomeStateCard({
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
        borderRadius: HomeStyles.cardRadius,
        border: HomeStyles.cardBorder,
        boxShadow: HomeStyles.cardShadow,
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
            FilledButton(
              onPressed: onActionPressed,
              style: HomeStyles.stateButtonStyle,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
