import 'package:flutter/material.dart';

import '../../models/ai/scan_document_result.dart';
import '../../models/braille/braille_mode.dart';
import '../../services/braille/braille_mode_translator.dart';
import '../../styles/screens/scan/scan_result_screen_styles.dart';
import '../common/skeleton.dart';
import 'braille_mode_selector.dart';

/// Builds a screen's text and Braille area for the mode being shown.
///
/// [view] is null only while Braille 1 is being prepared; show
/// [BrailleModeLoadingPlaceholder] then, never the Braille 2 content.
typedef BrailleModeContentBuilder =
    Widget Function(
      BuildContext context,
      BrailleModeView? view,
      Widget selector,
    );

/// Owns the Braille mode of one record on one screen.
///
/// Braille 2 is shown at once. Braille 1 is prepared before it is shown,
/// so the content never flashes Braille 2 first. A failure shows Braille 2
/// with a short note, never a blank or error screen.
class BrailleModeSection extends StatefulWidget {
  const BrailleModeSection({
    super.key,
    required this.pages,
    required this.initialMode,
    required this.builder,
    this.initialView,
    this.onViewChanged,
    this.translator,
    this.selectorLayout = BrailleModeSelectorLayout.chips,
  });

  /// How the selector handed to [builder] is drawn.
  final BrailleModeSelectorLayout selectorLayout;

  final List<DocumentPage> pages;
  final BrailleMode initialMode;
  final BrailleModeContentBuilder builder;

  /// A view prepared before this screen opened (for example while the scan
  /// overlay was still showing).
  final BrailleModeView? initialView;

  /// Called whenever a new view is shown, so screens can copy or save the
  /// mode on screen.
  final ValueChanged<BrailleModeView>? onViewChanged;

  final BrailleModeTranslator? translator;

  @override
  State<BrailleModeSection> createState() => _BrailleModeSectionState();
}

class _BrailleModeSectionState extends State<BrailleModeSection> {
  late BrailleMode _requested;
  BrailleModeView? _view;
  int _request = 0;

  late final BrailleModeAvailability _availability = _translator.availabilityOf(
    widget.pages,
  );

  BrailleModeTranslator get _translator {
    return widget.translator ?? BrailleModeTranslator.instance;
  }

  @override
  void initState() {
    super.initState();

    _requested = widget.initialMode;

    final BrailleModeView? initialView = widget.initialView;

    if (initialView != null) {
      _show(initialView);
    } else if (_requested == BrailleMode.contracted) {
      _show(_contractedView());
    } else {
      _prepare(_requested);
    }
  }

  BrailleModeView _contractedView() {
    return BrailleModeView(pages: widget.pages, mode: BrailleMode.contracted);
  }

  void _show(BrailleModeView view) {
    _view = view;
    widget.onViewChanged?.call(view);
  }

  Future<void> _prepare(BrailleMode mode) async {
    final int request = ++_request;

    final BrailleModeView view = await _translator.viewFor(widget.pages, mode);

    // Ignore results of a mode the user has already switched away from.
    if (!mounted || request != _request) {
      return;
    }

    setState(() {
      _show(view);
    });
  }

  void _select(BrailleMode mode) {
    if (mode == _requested && _view != null) {
      return;
    }

    setState(() {
      _requested = mode;

      if (mode == BrailleMode.contracted) {
        _request++;
        _show(_contractedView());
      } else {
        _view = null;
      }
    });

    if (mode == BrailleMode.uncontracted) {
      _prepare(mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final BrailleModeView? view = _view;

    final Widget selector = BrailleModeSelector(
      layout: widget.selectorLayout,
      selected: view?.mode ?? _requested,
      availability: _availability,
      showFallbackNote:
          _requested == BrailleMode.uncontracted &&
          view != null &&
          view.fellBack,
      onChanged: _select,
    );

    return widget.builder(context, view, selector);
  }
}

/// Shown in place of the text and Braille while Braille 1 is prepared.
class BrailleModeLoadingPlaceholder extends StatelessWidget {
  const BrailleModeLoadingPlaceholder({super.key});

  static const Color _baseColor = Color(0xFFE4EBF5);
  static const Color _highlightColor = Color(0xFFF4F7FC);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: ScanResultScreenStyles.contentPreviewPadding,
      child: SkeletonScope(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SkeletonLine(
              style: ScanResultScreenStyles.recognizedContentStyle,
              widthFactor: 0.8,
              baseColor: _baseColor,
              highlightColor: _highlightColor,
            ),
            SkeletonLine(
              style: ScanResultScreenStyles.brailleContentStyle,
              widthFactor: 0.65,
              baseColor: _baseColor,
              highlightColor: _highlightColor,
            ),
            SizedBox(height: ScanResultScreenStyles.wordRowSpacing),
            SkeletonLine(
              style: ScanResultScreenStyles.recognizedContentStyle,
              widthFactor: 0.6,
              baseColor: _baseColor,
              highlightColor: _highlightColor,
            ),
            SkeletonLine(
              style: ScanResultScreenStyles.brailleContentStyle,
              widthFactor: 0.5,
              baseColor: _baseColor,
              highlightColor: _highlightColor,
            ),
          ],
        ),
      ),
    );
  }
}
