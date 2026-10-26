import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/models/materials/material_folder_model.dart';
import 'package:mobile/models/materials/material_model.dart';
import 'package:mobile/screens/main/tab_data_cache.dart';
import 'package:mobile/screens/materials/material_screen.dart';
import 'package:mobile/services/materials/material_folder_service.dart';
import 'package:mobile/services/materials/material_service.dart';
import 'package:mobile/utils/session_manager.dart';

class _FakeMaterialService extends MaterialService {
  @override
  Future<List<MaterialModel>> getMaterials() async => <MaterialModel>[];
}

class _FakeFolderService extends MaterialFolderService {
  _FakeFolderService(this.folders);

  final List<MaterialFolderModel> folders;

  @override
  Future<List<MaterialFolderModel>> getFolders() async => folders;
}

final List<MaterialFolderModel> _folders = <MaterialFolderModel>[
  MaterialFolderModel(
    id: 7,
    name: 'Quadratic equations',
    itemCount: 12,
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
  ),
];

/// Pumps the Materials screen on a 320x568 phone with [textScale] and
/// returns the render objects that reported an overflow.
Future<List<RenderObject>> _pumpScreen(
  WidgetTester tester, {
  required double textScale,
}) async {
  tester.view.physicalSize = const Size(640, 1136);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final List<RenderObject> overflowing = <RenderObject>[];
  final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (!details.toString().contains('overflowed')) {
      previous?.call(details);
      return;
    }
    for (final DiagnosticsNode info
        in details.informationCollector?.call() ?? const <DiagnosticsNode>[]) {
      final Object? value = info.value;
      if (value is RenderObject) {
        overflowing.add(value);
      }
    }
  };
  addTearDown(() => FlutterError.onError = previous);

  final TabDataCache cache = TabDataCache()
    ..materials = (
      materials: const <MaterialModel>[],
      folders: _folders,
      isGuest: true,
    );

  await tester.pumpWidget(
    MaterialApp(
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        );
      },
      home: MaterialsScreen(
        cache: cache,
        onBack: () {},
        materialService: _FakeMaterialService(),
        folderService: _FakeFolderService(_folders),
      ),
    ),
  );
  await tester.pump();

  return overflowing;
}

/// Render objects inside the horizontal folders strip.
Set<RenderObject> _stripRenderObjects(WidgetTester tester) {
  final Finder strip = find.ancestor(
    of: find.text('Add Folder'),
    matching: find.byWidgetPredicate(
      (Widget widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.right,
    ),
  );
  expect(strip, findsOneWidget);

  return find
      .descendant(of: strip, matching: find.byWidgetPredicate((_) => true))
      .evaluate()
      .map((Element element) => element.renderObject)
      .whereType<RenderObject>()
      .toSet();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SessionManager.guestModeKey: true,
    });
  });

  testWidgets('folders strip keeps its usual height (132) at normal text', (
    WidgetTester tester,
  ) async {
    await _pumpScreen(tester, textScale: 1);

    final Finder strip = find.ancestor(
      of: find.text('Add Folder'),
      matching: find.byWidgetPredicate(
        (Widget widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.right,
      ),
    );
    expect(tester.getSize(strip).height, 132);
  });

  for (final double scale in <double>[1, 1.5, 2]) {
    testWidgets('folders strip has no overflow at ${scale}x text on 320x568', (
      WidgetTester tester,
    ) async {
      final List<RenderObject> overflowing = await _pumpScreen(
        tester,
        textScale: scale,
      );

      expect(find.text('Add Folder'), findsOneWidget);
      expect(find.text('Quadratic equations'), findsOneWidget);

      final Set<RenderObject> strip = _stripRenderObjects(tester);
      expect(strip, isNotEmpty);
      expect(overflowing.where(strip.contains), isEmpty);
    });

    testWidgets('"Folders" heading stays on one line at ${scale}x text', (
      WidgetTester tester,
    ) async {
      await _pumpScreen(tester, textScale: scale);

      final RenderParagraph heading = tester.renderObject<RenderParagraph>(
        find.text('Folders'),
      );
      final double oneLine = TextScaler.linear(scale).scale(16) * 1.2;

      expect(heading.size.height, lessThan(oneLine * 1.5));
    });
  }
}
