import 'package:flutter/material.dart';

enum ScanMode { ueb, nemeth }

class ScanModeSelector extends StatelessWidget {
  final ScanMode selectedMode;
  final ValueChanged<ScanMode> onModeChanged;

  const ScanModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SegmentedButton<ScanMode>(
        segments: const [
          ButtonSegment(
            value: ScanMode.ueb,
            icon: Icon(Icons.text_fields),
            label: Text("Text (UEB)"),
          ),
          ButtonSegment(
            value: ScanMode.nemeth,
            icon: Icon(Icons.calculate),
            label: Text("Math (Nemeth)"),
          ),
        ],

        selected: {selectedMode},

        onSelectionChanged: (selection) {
          onModeChanged(selection.first);
        },
      ),
    );
  }
}
