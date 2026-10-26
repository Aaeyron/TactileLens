import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/models/materials/material_folder_model.dart';
import 'package:mobile/models/materials/material_model.dart';
import 'package:mobile/screens/main/tab_data_cache.dart';
import 'package:mobile/screens/materials/material_screen.dart';
import 'package:mobile/services/materials/material_folder_service.dart';
import 'package:mobile/services/materials/material_service.dart';
import 'package:mobile/utils/session_manager.dart';
import 'package:mobile/widgets/materials/materials_empty_state.dart';

class _FakeMaterialService extends MaterialService {
  @override
  Future<List<MaterialModel>> getMaterials() async => <MaterialModel>[];
}

class _FakeFolderService extends MaterialFolderService {
  @override
  Future<List<MaterialFolderModel>> getFolders() async =>
      <MaterialFolderModel>[];
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SessionManager.guestModeKey: true,
    });
  });

  for (final double scale in <double>[1, 2]) {
    testWidgets('empty state has no overflow at ${scale}x text on 320x568', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(640, 1136);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      // Record the render objects that overflow; only the empty state's
      // count here.
      final List<RenderObject> overflowing = <RenderObject>[];
      final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (!details.toString().contains('overflowed')) {
          previous?.call(details);
          return;
        }
        for (final DiagnosticsNode info
            in details.informationCollector?.call() ??
                const <DiagnosticsNode>[]) {
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
          folders: const <MaterialFolderModel>[],
          isGuest: true,
        );

      await tester.pumpWidget(
        MaterialApp(
          builder: (BuildContext context, Widget? child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            );
          },
          home: MaterialsScreen(
            cache: cache,
            onBack: () {},
            materialService: _FakeMaterialService(),
            folderService: _FakeFolderService(),
          ),
        ),
      );
      await tester.pump();

      final Finder emptyState = find.byType(MaterialsEmptyState);
      await tester.scrollUntilVisible(
        find.text('No Materials Yet'),
        120,
        scrollable: find
            .byWidgetPredicate(
              (Widget widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            )
            .first,
      );
      expect(emptyState, findsOneWidget);

      final Set<RenderObject> inEmptyState = find
          .descendant(
            of: emptyState,
            matching: find.byWidgetPredicate((_) => true),
          )
          .evaluate()
          .map((Element element) => element.renderObject)
          .whereType<RenderObject>()
          .toSet();
      expect(inEmptyState, isNotEmpty);
      expect(overflowing.where(inEmptyState.contains), isEmpty);

      // The whole description is shown, not cut off.
      expect(
        find.textContaining('Nemeth Braille translation.'),
        findsOneWidget,
      );
    });
  }
}
