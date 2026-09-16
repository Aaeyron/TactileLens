import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/settings/settings_service.dart';
import '../../styles/screens/profile/settings_screen_styles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() {
    return _SettingsScreenState();
  }
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _entranceOpacity;
  late final Animation<Offset> _entrancePosition;

  AppTextSize _textSize = AppTextSize.defaultSize;

  RecognitionPreference _recognitionPreference = RecognitionPreference.faster;

  bool _highContrastEnabled = false;
  bool _reduceAnimationsEnabled = false;
  bool _hapticFeedbackEnabled = true;
  bool _preserveLayoutEnabled = true;
  bool _autoSaveScansEnabled = true;
  bool _contractedUebEnabled = false;

  bool _isLoading = true;
  bool _isResetting = false;

  @override
  void initState() {
    super.initState();

    _initializeEntranceAnimation();
    _loadSettings();
  }

  void _initializeEntranceAnimation() {
    _entranceController = AnimationController(
      vsync: this,
      duration: SettingsScreenStyles.entranceDuration,
    );

    final CurvedAnimation entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: SettingsScreenStyles.entranceCurve,
    );

    _entranceOpacity = entranceAnimation;

    _entrancePosition = Tween<Offset>(
      begin: SettingsScreenStyles.entranceBeginOffset,
      end: Offset.zero,
    ).animate(entranceAnimation);

    Future<void>.delayed(SettingsScreenStyles.entranceDelay, () {
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

  Future<void> _loadSettings() async {
    try {
      final AppTextSize textSize = await SettingsService.getTextSize();

      final RecognitionPreference recognitionPreference =
          await SettingsService.getRecognitionPreference();

      final bool highContrastEnabled =
          await SettingsService.getHighContrastEnabled();

      final bool reduceAnimationsEnabled =
          await SettingsService.getReduceAnimationsEnabled();

      final bool hapticFeedbackEnabled =
          await SettingsService.getHapticFeedbackEnabled();

      final bool preserveLayoutEnabled =
          await SettingsService.getPreserveLayoutEnabled();

      final bool autoSaveScansEnabled =
          await SettingsService.getAutoSaveScansEnabled();

      final bool contractedUebEnabled =
          await SettingsService.getContractedUebEnabled();

      if (!mounted) {
        return;
      }

      setState(() {
        _textSize = textSize;
        _recognitionPreference = recognitionPreference;
        _highContrastEnabled = highContrastEnabled;
        _reduceAnimationsEnabled = reduceAnimationsEnabled;
        _hapticFeedbackEnabled = hapticFeedbackEnabled;
        _preserveLayoutEnabled = preserveLayoutEnabled;
        _autoSaveScansEnabled = autoSaveScansEnabled;
        _contractedUebEnabled = contractedUebEnabled;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage(SettingsScreenStyles.loadErrorMessage);
    }
  }

  Future<void> _changeTextSize(AppTextSize? value) async {
    if (value == null || value == _textSize) {
      return;
    }

    final AppTextSize previousValue = _textSize;

    setState(() {
      _textSize = value;
    });

    try {
      await SettingsService.setTextSize(value);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _textSize = previousValue;
      });

      _showMessage(SettingsScreenStyles.saveErrorMessage);
    }
  }

  Future<void> _changeRecognitionPreference(
    RecognitionPreference? value,
  ) async {
    if (value == null || value == _recognitionPreference) {
      return;
    }

    final RecognitionPreference previousValue = _recognitionPreference;

    setState(() {
      _recognitionPreference = value;
    });

    try {
      await SettingsService.setRecognitionPreference(value);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _recognitionPreference = previousValue;
      });

      _showMessage(SettingsScreenStyles.saveErrorMessage);
    }
  }

  Future<void> _changeHighContrast(bool value) async {
    final bool previousValue = _highContrastEnabled;

    setState(() {
      _highContrastEnabled = value;
    });

    try {
      await SettingsService.setHighContrastEnabled(value);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _highContrastEnabled = previousValue;
      });

      _showMessage(SettingsScreenStyles.saveErrorMessage);
    }
  }

  Future<void> _changeReduceAnimations(bool value) async {
    final bool previousValue = _reduceAnimationsEnabled;

    setState(() {
      _reduceAnimationsEnabled = value;
    });

    try {
      await SettingsService.setReduceAnimationsEnabled(value);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _reduceAnimationsEnabled = previousValue;
      });

      _showMessage(SettingsScreenStyles.saveErrorMessage);
    }
  }

  Future<void> _changeHapticFeedback(bool value) async {
    final bool previousValue = _hapticFeedbackEnabled;

    setState(() {
      _hapticFeedbackEnabled = value;
    });

    try {
      if (value) {
        await HapticFeedback.selectionClick();
      }

      await SettingsService.setHapticFeedbackEnabled(value);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _hapticFeedbackEnabled = previousValue;
      });

      _showMessage(SettingsScreenStyles.saveErrorMessage);
    }
  }

  Future<void> _changePreserveLayout(bool value) async {
    final bool previousValue = _preserveLayoutEnabled;

    setState(() {
      _preserveLayoutEnabled = value;
    });

    try {
      await SettingsService.setPreserveLayoutEnabled(value);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _preserveLayoutEnabled = previousValue;
      });

      _showMessage(SettingsScreenStyles.saveErrorMessage);
    }
  }

  Future<void> _changeAutoSaveScans(bool value) async {
    final bool previousValue = _autoSaveScansEnabled;

    setState(() {
      _autoSaveScansEnabled = value;
    });

    try {
      await SettingsService.setAutoSaveScansEnabled(value);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _autoSaveScansEnabled = previousValue;
      });

      _showMessage(SettingsScreenStyles.saveErrorMessage);
    }
  }

  Future<void> _changeContractedUeb(bool value) async {
    final bool previousValue = _contractedUebEnabled;

    setState(() {
      _contractedUebEnabled = value;
    });

    try {
      await SettingsService.setContractedUebEnabled(value);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _contractedUebEnabled = previousValue;
      });

      _showMessage(SettingsScreenStyles.saveErrorMessage);
    }
  }

  Future<void> _confirmResetSettings() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierColor: SettingsScreenStyles.dialogBarrierColor,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: SettingsScreenStyles.surfaceColor,
          shape: const RoundedRectangleBorder(
            borderRadius: SettingsScreenStyles.dialogRadius,
            side: BorderSide(color: SettingsScreenStyles.outlineColor),
          ),
          title: const Text(
            SettingsScreenStyles.resetDialogTitle,
            style: SettingsScreenStyles.dialogTitleStyle,
          ),
          content: const Text(
            SettingsScreenStyles.resetDialogDescription,
            style: SettingsScreenStyles.dialogDescriptionStyle,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(SettingsScreenStyles.cancelLabel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: SettingsScreenStyles.dangerColor,
                foregroundColor: SettingsScreenStyles.surfaceColor,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(SettingsScreenStyles.resetLabel),
            ),
          ],
        );
      },
    );

    if (confirmed != true || _isResetting) {
      return;
    }

    setState(() {
      _isResetting = true;
    });

    try {
      await SettingsService.resetSettings();

      if (!mounted) {
        return;
      }

      setState(() {
        _textSize = AppTextSize.defaultSize;
        _recognitionPreference = RecognitionPreference.faster;
        _highContrastEnabled = false;
        _reduceAnimationsEnabled = false;
        _hapticFeedbackEnabled = true;
        _preserveLayoutEnabled = true;
        _autoSaveScansEnabled = true;
        _contractedUebEnabled = false;
        _isResetting = false;
      });

      _showMessage(SettingsScreenStyles.resetSuccessMessage);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isResetting = false;
      });

      _showMessage(SettingsScreenStyles.resetErrorMessage);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: SettingsScreenStyles.snackBarDuration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: SettingsScreenStyles.primaryColor,
          margin: SettingsScreenStyles.snackBarMargin,
          shape: const RoundedRectangleBorder(
            borderRadius: SettingsScreenStyles.snackBarRadius,
          ),
          content: Text(message, style: SettingsScreenStyles.snackBarTextStyle),
        ),
      );
  }

  String _textSizeLabel(AppTextSize value) {
    switch (value) {
      case AppTextSize.defaultSize:
        return SettingsScreenStyles.defaultTextSizeLabel;
      case AppTextSize.large:
        return SettingsScreenStyles.largeTextSizeLabel;
      case AppTextSize.extraLarge:
        return SettingsScreenStyles.extraLargeTextSizeLabel;
    }
  }

  String _recognitionPreferenceLabel(RecognitionPreference value) {
    switch (value) {
      case RecognitionPreference.faster:
        return SettingsScreenStyles.fasterRecognitionLabel;
      case RecognitionPreference.moreAccurate:
        return SettingsScreenStyles.accurateRecognitionLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: SettingsScreenStyles.backgroundColor,
        body: FadeTransition(
          opacity: _entranceOpacity,
          child: SlideTransition(
            position: _entrancePosition,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverPadding(
                  padding: SettingsScreenStyles.contentPadding,
                  sliver: SliverToBoxAdapter(
                    child: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 80),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: SettingsScreenStyles.primaryColor,
                              ),
                            ),
                          )
                        : Column(
                            children: <Widget>[
                              _SettingsSection(
                                title: SettingsScreenStyles.accessibilityTitle,
                                children: <Widget>[
                                  _SettingsDropdownItem<AppTextSize>(
                                    icon: SettingsScreenStyles.textSizeIcon,
                                    title: SettingsScreenStyles.textSizeTitle,
                                    description: SettingsScreenStyles
                                        .textSizeDescription,
                                    value: _textSize,
                                    values: AppTextSize.values,
                                    labelBuilder: _textSizeLabel,
                                    onChanged: _changeTextSize,
                                    showDivider: true,
                                  ),
                                  _SettingsSwitchItem(
                                    icon: SettingsScreenStyles.highContrastIcon,
                                    title:
                                        SettingsScreenStyles.highContrastTitle,
                                    description: SettingsScreenStyles
                                        .highContrastDescription,
                                    value: _highContrastEnabled,
                                    onChanged: _changeHighContrast,
                                    showDivider: true,
                                  ),
                                  _SettingsSwitchItem(
                                    icon: SettingsScreenStyles
                                        .reduceAnimationsIcon,
                                    title: SettingsScreenStyles
                                        .reduceAnimationsTitle,
                                    description: SettingsScreenStyles
                                        .reduceAnimationsDescription,
                                    value: _reduceAnimationsEnabled,
                                    onChanged: _changeReduceAnimations,
                                    showDivider: true,
                                  ),
                                  _SettingsSwitchItem(
                                    icon:
                                        SettingsScreenStyles.hapticFeedbackIcon,
                                    title: SettingsScreenStyles
                                        .hapticFeedbackTitle,
                                    description: SettingsScreenStyles
                                        .hapticFeedbackDescription,
                                    value: _hapticFeedbackEnabled,
                                    onChanged: _changeHapticFeedback,
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: SettingsScreenStyles.sectionSpacing,
                              ),
                              _SettingsSection(
                                title: SettingsScreenStyles.scanningTitle,
                                children: <Widget>[
                                  _SettingsDropdownItem<RecognitionPreference>(
                                    icon: SettingsScreenStyles.recognitionIcon,
                                    title: SettingsScreenStyles
                                        .recognitionPreferenceTitle,
                                    description: SettingsScreenStyles
                                        .recognitionPreferenceDescription,
                                    value: _recognitionPreference,
                                    values: RecognitionPreference.values,
                                    labelBuilder: _recognitionPreferenceLabel,
                                    onChanged: _changeRecognitionPreference,
                                    showDivider: true,
                                  ),
                                  _SettingsSwitchItem(
                                    icon:
                                        SettingsScreenStyles.preserveLayoutIcon,
                                    title: SettingsScreenStyles
                                        .preserveLayoutTitle,
                                    description: SettingsScreenStyles
                                        .preserveLayoutDescription,
                                    value: _preserveLayoutEnabled,
                                    onChanged: _changePreserveLayout,
                                    showDivider: true,
                                  ),
                                  _SettingsSwitchItem(
                                    icon: SettingsScreenStyles.autoSaveIcon,
                                    title: SettingsScreenStyles.autoSaveTitle,
                                    description: SettingsScreenStyles
                                        .autoSaveDescription,
                                    value: _autoSaveScansEnabled,
                                    onChanged: _changeAutoSaveScans,
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: SettingsScreenStyles.sectionSpacing,
                              ),
                              _SettingsSection(
                                title: SettingsScreenStyles.brailleTitle,
                                children: <Widget>[
                                  _SettingsSwitchItem(
                                    icon:
                                        SettingsScreenStyles.contractedUebIcon,
                                    title:
                                        SettingsScreenStyles.contractedUebTitle,
                                    description: SettingsScreenStyles
                                        .contractedUebDescription,
                                    value: _contractedUebEnabled,
                                    onChanged: _changeContractedUeb,
                                    showDivider: true,
                                  ),
                                  const _SettingsInformationItem(
                                    icon: SettingsScreenStyles.nemethIcon,
                                    title: SettingsScreenStyles.nemethTitle,
                                    description:
                                        SettingsScreenStyles.nemethDescription,
                                    value: SettingsScreenStyles.automaticLabel,
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: SettingsScreenStyles.sectionSpacing,
                              ),
                              _SettingsSection(
                                title: SettingsScreenStyles.resetTitle,
                                children: <Widget>[
                                  _SettingsResetItem(
                                    isResetting: _isResetting,
                                    onPressed: _confirmResetSettings,
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: SettingsScreenStyles.bottomSpacing,
                              ),
                            ],
                          ),
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
        SettingsScreenStyles.headerHorizontalPadding,
        statusBarHeight + SettingsScreenStyles.headerTopPadding,
        SettingsScreenStyles.headerHorizontalPadding,
        SettingsScreenStyles.headerBottomPadding,
      ),
      decoration: const BoxDecoration(
        gradient: SettingsScreenStyles.headerGradient,
        borderRadius: SettingsScreenStyles.headerRadius,
      ),
      child: Stack(
        children: <Widget>[
          const Positioned(
            right: SettingsScreenStyles.decorationRight,
            bottom: SettingsScreenStyles.decorationBottom,
            child: _HeaderBrailleDecoration(),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    tooltip: SettingsScreenStyles.backTooltip,
                    onPressed: () {
                      Navigator.of(context).maybePop();
                    },
                    style: SettingsScreenStyles.backButtonStyle,
                    icon: const Icon(
                      SettingsScreenStyles.backIcon,
                      size: SettingsScreenStyles.backIconSize,
                    ),
                  ),
                  const SizedBox(width: SettingsScreenStyles.headerBackSpacing),
                  const Expanded(
                    child: Text(
                      SettingsScreenStyles.screenTitle,
                      style: SettingsScreenStyles.headerTitleStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SettingsScreenStyles.headerTextSpacing),
              const Padding(
                padding: SettingsScreenStyles.headerDescriptionPadding,
                child: SizedBox(
                  width: SettingsScreenStyles.headerDescriptionWidth,
                  child: Text(
                    SettingsScreenStyles.screenDescription,
                    style: SettingsScreenStyles.headerDescriptionStyle,
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

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(title, style: SettingsScreenStyles.sectionTitleStyle),
        ),
        const SizedBox(height: SettingsScreenStyles.sectionTitleBottomSpacing),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: SettingsScreenStyles.surfaceColor,
            borderRadius: SettingsScreenStyles.cardRadius,
            border: SettingsScreenStyles.cardBorder,
            boxShadow: SettingsScreenStyles.cardShadow,
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsSwitchItem extends StatelessWidget {
  const _SettingsSwitchItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.showDivider = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: showDivider
          ? const BoxDecoration(border: SettingsScreenStyles.itemDividerBorder)
          : null,
      child: SwitchListTile(
        contentPadding: SettingsScreenStyles.settingItemPadding,
        secondary: _SettingsIcon(icon: icon),
        title: Text(title, style: SettingsScreenStyles.settingTitleStyle),
        subtitle: Padding(
          padding: const EdgeInsets.only(
            top: SettingsScreenStyles.settingDescriptionSpacing,
          ),
          child: Text(
            description,
            style: SettingsScreenStyles.settingDescriptionStyle,
          ),
        ),
        value: value,
        activeThumbColor: SettingsScreenStyles.primaryColor,
        inactiveThumbColor: SettingsScreenStyles.switchInactiveThumbColor,
        inactiveTrackColor: SettingsScreenStyles.switchInactiveTrackColor,
        onChanged: onChanged,
      ),
    );
  }
}

class _SettingsDropdownItem<T> extends StatelessWidget {
  const _SettingsDropdownItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
    this.showDivider = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final T value;
  final List<T> values;
  final String Function(T value) labelBuilder;
  final ValueChanged<T?> onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: SettingsScreenStyles.settingItemPadding,
      decoration: showDivider
          ? const BoxDecoration(border: SettingsScreenStyles.itemDividerBorder)
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _SettingsIcon(icon: icon),
          const SizedBox(width: SettingsScreenStyles.settingContentSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: SettingsScreenStyles.settingTitleStyle),
                const SizedBox(
                  height: SettingsScreenStyles.settingDescriptionSpacing,
                ),
                Text(
                  description,
                  style: SettingsScreenStyles.settingDescriptionStyle,
                ),
              ],
            ),
          ),
          const SizedBox(width: SettingsScreenStyles.settingControlSpacing),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: SettingsScreenStyles.dropdownMaximumWidth,
            ),
            child: Container(
              padding: SettingsScreenStyles.dropdownPadding,
              decoration: const BoxDecoration(
                color: SettingsScreenStyles.primarySoftColor,
                borderRadius: SettingsScreenStyles.dropdownRadius,
                border: SettingsScreenStyles.dropdownBorder,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value: value,
                  isDense: true,
                  style: SettingsScreenStyles.dropdownTextStyle,
                  iconEnabledColor: SettingsScreenStyles.primaryColor,
                  dropdownColor: SettingsScreenStyles.surfaceColor,
                  items: values
                      .map((T item) {
                        return DropdownMenuItem<T>(
                          value: item,
                          child: Text(
                            labelBuilder(item),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      })
                      .toList(growable: false),
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsInformationItem extends StatelessWidget {
  const _SettingsInformationItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String description;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: SettingsScreenStyles.settingItemPadding,
      child: Row(
        children: <Widget>[
          _SettingsIcon(icon: icon),
          const SizedBox(width: SettingsScreenStyles.settingContentSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: SettingsScreenStyles.settingTitleStyle),
                const SizedBox(
                  height: SettingsScreenStyles.settingDescriptionSpacing,
                ),
                Text(
                  description,
                  style: SettingsScreenStyles.settingDescriptionStyle,
                ),
              ],
            ),
          ),
          const SizedBox(width: SettingsScreenStyles.settingControlSpacing),
          Text(value, style: SettingsScreenStyles.informationValueStyle),
        ],
      ),
    );
  }
}

class _SettingsResetItem extends StatelessWidget {
  const _SettingsResetItem({
    required this.isResetting,
    required this.onPressed,
  });

  final bool isResetting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isResetting ? null : onPressed,
        child: Padding(
          padding: SettingsScreenStyles.resetItemPadding,
          child: Row(
            children: <Widget>[
              const _SettingsIcon(
                icon: SettingsScreenStyles.resetIcon,
                isDanger: true,
              ),
              const SizedBox(width: SettingsScreenStyles.settingContentSpacing),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      SettingsScreenStyles.resetSettingsTitle,
                      style: SettingsScreenStyles.resetTitleStyle,
                    ),
                    SizedBox(
                      height: SettingsScreenStyles.settingDescriptionSpacing,
                    ),
                    Text(
                      SettingsScreenStyles.resetSettingsDescription,
                      style: SettingsScreenStyles.settingDescriptionStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: SettingsScreenStyles.settingControlSpacing),
              if (isResetting)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: SettingsScreenStyles.dangerColor,
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: SettingsScreenStyles.dangerColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon, this.isDanger = false});

  final IconData icon;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: SettingsScreenStyles.iconContainerSize,
      height: SettingsScreenStyles.iconContainerSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDanger
            ? SettingsScreenStyles.dangerSoftColor
            : SettingsScreenStyles.primarySoftColor,
        borderRadius: SettingsScreenStyles.iconContainerRadius,
      ),
      child: Icon(
        icon,
        size: SettingsScreenStyles.iconSize,
        color: isDanger
            ? SettingsScreenStyles.dangerColor
            : SettingsScreenStyles.primaryColor,
      ),
    );
  }
}

class _HeaderBrailleDecoration extends StatelessWidget {
  const _HeaderBrailleDecoration();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: SettingsScreenStyles.decorationOpacity,
      child: SizedBox(
        width: SettingsScreenStyles.decorationWidth,
        child: Wrap(
          spacing: SettingsScreenStyles.decorationDotSpacing,
          runSpacing: SettingsScreenStyles.decorationDotSpacing,
          children: List<Widget>.generate(
            SettingsScreenStyles.decorationDotCount,
            (int index) {
              return const DecoratedBox(
                decoration: BoxDecoration(
                  color: SettingsScreenStyles.surfaceColor,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: SettingsScreenStyles.decorationDotSize,
                  height: SettingsScreenStyles.decorationDotSize,
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
