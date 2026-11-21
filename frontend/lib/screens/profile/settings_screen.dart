import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/braille/braille_mode.dart';
import '../../services/braille/braille_mode_translator.dart';
import '../../services/settings/settings_service.dart';
import '../../styles/screens/profile/settings_screen_styles.dart';
import '../../widgets/braille/braille_mode_selector.dart';
import '../../widgets/common/header_braille_dots.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() {
    return _SettingsScreenState();
  }
}

class _SettingsScreenState extends State<SettingsScreen> {
  BrailleMode _brailleMode = BrailleMode.defaultMode;

  bool _isLoading = true;
  bool _isResetting = false;

  @override
  void initState() {
    super.initState();

    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final BrailleMode brailleMode = await SettingsService.getBrailleMode();

      if (!mounted) {
        return;
      }

      setState(() {
        _brailleMode = brailleMode;
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

  Future<void> _changeBrailleMode(BrailleMode value) async {
    final BrailleMode previousValue = _brailleMode;

    setState(() {
      _brailleMode = value;
    });

    try {
      await SettingsService.setBrailleMode(value);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _brailleMode = previousValue;
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
        _brailleMode = BrailleMode.defaultMode;
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

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: SettingsScreenStyles.backgroundColor,
        body: CustomScrollView(
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
                          // Text size, contrast and animations come from
                          // the phone's own settings (the app follows
                          // them); the app has no separate controls.
                          const _SettingsSection(
                            title: SettingsScreenStyles.accessibilityTitle,
                            children: <Widget>[
                              _SettingsInformationItem(
                                icon: SettingsScreenStyles.textSizeIcon,
                                title: SettingsScreenStyles.displayTitle,
                                description:
                                    SettingsScreenStyles.displayDescription,
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: SettingsScreenStyles.sectionSpacing,
                          ),
                          _SettingsSection(
                            title: SettingsScreenStyles.brailleTitle,
                            children: <Widget>[
                              _SettingsBrailleModeItem(
                                value: _brailleMode,
                                onChanged: _changeBrailleMode,
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
            child: HeaderBrailleDots(),
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
          child: Material(
            color: Colors.transparent,
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class _SettingsBrailleModeItem extends StatelessWidget {
  const _SettingsBrailleModeItem({
    required this.value,
    required this.onChanged,
  });

  final BrailleMode value;
  final ValueChanged<BrailleMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    return Container(
      decoration: const BoxDecoration(
        border: SettingsScreenStyles.itemDividerBorder,
      ),
      padding: SettingsScreenStyles.settingItemPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SettingsIcon(icon: SettingsScreenStyles.brailleModeIcon),
          const SizedBox(width: SettingsScreenStyles.brailleModeIconSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  SettingsScreenStyles.brailleModeTitle,
                  style: SettingsScreenStyles.settingTitleStyle,
                ),
                const SizedBox(
                  height: SettingsScreenStyles.settingDescriptionSpacing,
                ),
                const Text(
                  SettingsScreenStyles.brailleModeDescription,
                  style: SettingsScreenStyles.settingDescriptionStyle,
                ),
                const SizedBox(
                  height: SettingsScreenStyles.brailleModeSelectorSpacing,
                ),
                BrailleModeSelector(
                  selected: isAndroid ? value : BrailleMode.contracted,
                  availability: isAndroid
                      ? BrailleModeAvailability.available
                      : BrailleModeAvailability.unsupportedPlatform,
                  onChanged: onChanged,
                ),
              ],
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
    this.value,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? value;

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
          if (value != null) ...<Widget>[
            const SizedBox(width: SettingsScreenStyles.settingControlSpacing),
            // Wraps instead of overflowing with large text.
            Flexible(
              child: Text(
                value!,
                textAlign: TextAlign.end,
                style: SettingsScreenStyles.informationValueStyle,
              ),
            ),
          ],
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
