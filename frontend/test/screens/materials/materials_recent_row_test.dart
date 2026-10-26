import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/models/materials/material_folder_model.dart';
import 'package:mobile/models/materials/material_model.dart';
import 'package:mobile/screens/main/tab_data_cache.dart';
import 'package:mobile/screens/materials/material_preview_screen.dart';
import 'package:mobile/screens/materials/material_screen.dart';
import 'package:mobile/services/materials/material_folder_service.dart';
import 'package:mobile/services/materials/material_service.dart';
import 'package:mobile/utils/session_manager.dart';

const String _title = 'Quadratic equations worksheet, chapter 4 review';
const String _moreOptions = 'More options for $_title';

class _FakeMaterialService extends MaterialService {
  _FakeMaterialService(this.materials);

  List<MaterialModel> materials;
  final List<int> deletedIds = <int>[];

  @override
  Future<List<MaterialModel>> getMaterials() async => materials;

  @override
  Future<void> deleteMaterial(int id) async {
    deletedIds.add(id);
    materials = materials
        .where((MaterialModel material) => material.id != id)
        .toList(growable: false);
  }
}

class _FakeFolderService extends MaterialFolderService {
  _FakeFolderService(this.folders);

  final List<MaterialFolderModel> folders;

  @override
  Future<List<MaterialFolderModel>> getFolders() async => folders;
}

MaterialModel _material({int? folderId}) {
  return MaterialModel(
    id: 1,
    folderId: folderId,
    title: _title,
    subject: 'General Algebra',
    description: '',
    fileName: 'worksheet.pdf',
    fileType: 'application/pdf',
    fileSize: 1000,
    filePath: '',
    uploadDate: DateTime(2026, 10, 26, 15, 49),
    recognizedContent: 'x^2 + 3x - 4 = 0',
  );
}

MaterialFolderModel _folder({int itemCount = 0}) {
  return MaterialFolderModel(
    id: 7,
    name: 'Algebra',
    itemCount: itemCount,
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
  );
}

class _Harness {
  _Harness({required this.materials, required this.folders})
    : materialService = _FakeMaterialService(materials),
      folderService = _FakeFolderService(folders);

  final List<MaterialModel> materials;
  final List<MaterialFolderModel> folders;
  final _FakeMaterialService materialService;
  final _FakeFolderService folderService;

  Future<void> pump(WidgetTester tester, {double textScale = 1}) async {
    final TabDataCache cache = TabDataCache()
      ..materials = (materials: materials, folders: folders, isGuest: true);

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
          materialService: materialService,
          folderService: folderService,
        ),
      ),
    );
    await tester.pump();
  }
}

Future<void> _showRow(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text(_title),
    120,
    scrollable: find
        .byWidgetPredicate(
          (Widget widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        )
        .first,
  );
  await tester.pump();
}

Future<void> _openFolder(WidgetTester tester) async {
  await tester.tap(find.text('Algebra').first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SessionManager.guestModeKey: true,
    });
  });

  group('Recent Materials row', () {
    testWidgets('tapping the card opens the preview', (
      WidgetTester tester,
    ) async {
      await _Harness(
        materials: <MaterialModel>[_material()],
        folders: const <MaterialFolderModel>[],
      ).pump(tester);
      await _showRow(tester);

      await tester.tap(find.text(_title));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(MaterialDetailScreen), findsOneWidget);
    });

    testWidgets('three-dot button is 48 dp and opens the three actions', (
      WidgetTester tester,
    ) async {
      await _Harness(
        materials: <MaterialModel>[_material()],
        folders: const <MaterialFolderModel>[],
      ).pump(tester);
      await _showRow(tester);

      final Finder button = find.byTooltip(_moreOptions);
      expect(button, findsOneWidget);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);

      final Size size = tester.getSize(button);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Preview'), findsOneWidget);
      expect(find.text('Move to folder'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.byType(MaterialDetailScreen), findsNothing);
    });

    testWidgets('Preview in the menu opens the preview', (
      WidgetTester tester,
    ) async {
      await _Harness(
        materials: <MaterialModel>[_material()],
        folders: const <MaterialFolderModel>[],
      ).pump(tester);
      await _showRow(tester);

      await tester.tap(find.byTooltip(_moreOptions));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Preview'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(MaterialDetailScreen), findsOneWidget);
    });

    testWidgets('Move to folder opens the existing folder picker', (
      WidgetTester tester,
    ) async {
      await _Harness(
        materials: <MaterialModel>[_material()],
        folders: <MaterialFolderModel>[_folder()],
      ).pump(tester);
      await _showRow(tester);

      await tester.tap(find.byTooltip(_moreOptions));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move to folder'));
      await tester.pumpAndSettle();

      expect(find.text('Move to Folder'), findsOneWidget);
      expect(
        find.text('Choose where you want to organize this material.'),
        findsOneWidget,
      );
    });

    testWidgets('Delete asks first; Cancel keeps it, Delete removes it', (
      WidgetTester tester,
    ) async {
      final _Harness harness = _Harness(
        materials: <MaterialModel>[_material()],
        folders: const <MaterialFolderModel>[],
      );
      await harness.pump(tester);
      await _showRow(tester);

      await tester.tap(find.byTooltip(_moreOptions));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Material'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(harness.materialService.deletedIds, isEmpty);
      expect(find.text(_title), findsOneWidget);

      await tester.tap(find.byTooltip(_moreOptions));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Delete'),
        ),
      );
      await tester.pumpAndSettle();

      expect(harness.materialService.deletedIds, <int>[1]);
      expect(find.text(_title), findsNothing);
      expect(find.text('Material deleted successfully.'), findsOneWidget);
    });

    testWidgets('one TalkBack stop with the details and two custom actions', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final _Harness harness = _Harness(
        materials: <MaterialModel>[_material()],
        folders: const <MaterialFolderModel>[],
      );
      await harness.pump(tester);
      await _showRow(tester);

      final Finder row = find.bySemanticsLabel(RegExp('^$_title\\. '));
      expect(row, findsOneWidget);

      final SemanticsNode node = tester.getSemantics(row);
      final String label = node.label;
      expect(label, contains('General Algebra'));
      expect(label, contains('Math'));
      expect(label, contains('PDF'));

      expect(
        node,
        matchesSemantics(
          label: label,
          isButton: true,
          hasTapAction: true,
          customActions: const <CustomSemanticsAction>[
            CustomSemanticsAction(label: 'Move to folder'),
            CustomSemanticsAction(label: 'Delete'),
          ],
        ),
      );

      // The three-dot button and the texts are inside the one row node.
      expect(find.bySemanticsLabel(_moreOptions), findsNothing);
      expect(find.bySemanticsLabel(_title), findsNothing);

      // The Delete action reaches the same confirmation.
      node.owner!.performAction(
        node.id,
        SemanticsAction.customAction,
        CustomSemanticsAction.getIdentifier(
          const CustomSemanticsAction(label: 'Delete'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Delete Material'), findsOneWidget);
      expect(harness.materialService.deletedIds, isEmpty);

      semantics.dispose();
    });

    testWidgets('no overflow in the row at 320x568 with 2x text', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(640, 1136);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      // Record which render objects overflow; other parts of the screen
      // (the existing Add Folder card) are not part of this row.
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

      await _Harness(
        materials: <MaterialModel>[_material(folderId: 7)],
        folders: <MaterialFolderModel>[_folder(itemCount: 1)],
      ).pump(tester, textScale: 2);
      await _showRow(tester);

      Set<RenderObject> rowRenderObjects(Finder rowText) {
        final Finder row = find.ancestor(
          of: rowText,
          matching: find.byType(InkWell),
        );
        return find
            .descendant(
              of: row.first,
              matching: find.byWidgetPredicate(
                (Widget widget) => widget is Flex,
              ),
            )
            .evaluate()
            .map((Element element) => element.renderObject!)
            .toSet();
      }

      final Set<RenderObject> listRow = rowRenderObjects(
        find.text(_title).first,
      );
      expect(listRow, isNotEmpty);
      expect(overflowing.where(listRow.contains), isEmpty);

      // The row grew instead of overflowing.
      final double rowHeight = tester
          .getSize(
            find
                .ancestor(
                  of: find.text(_title).first,
                  matching: find.byType(InkWell),
                )
                .first,
          )
          .height;
      expect(rowHeight, greaterThan(100));

      // Same row inside the folder sheet.
      await tester.scrollUntilVisible(
        find.text('Algebra'),
        -120,
        scrollable: find
            .byWidgetPredicate(
              (Widget widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            )
            .first,
      );
      await _openFolder(tester);
      final Set<RenderObject> sheetRow = rowRenderObjects(
        find.text(_title).last,
      );
      expect(sheetRow, isNotEmpty);
      expect(overflowing.where(sheetRow.contains), isEmpty);

      FlutterError.onError = previous;
    });
  });

  group('Row inside the folder-contents sheet', () {
    Future<_Harness> openSheet(WidgetTester tester) async {
      final _Harness harness = _Harness(
        materials: <MaterialModel>[_material(folderId: 7)],
        folders: <MaterialFolderModel>[_folder(itemCount: 1)],
      );
      await harness.pump(tester);
      await _openFolder(tester);
      expect(find.byTooltip('Close folder'), findsOneWidget);
      return harness;
    }

    testWidgets('tapping the card opens the preview', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      await tester.tap(find.text(_title).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(MaterialDetailScreen), findsOneWidget);
    });

    testWidgets('three-dot menu has the three actions and Delete confirms', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await openSheet(tester);

      await tester.tap(find.byTooltip(_moreOptions).last);
      await tester.pumpAndSettle();

      expect(find.text('Preview'), findsOneWidget);
      expect(find.text('Move to folder'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Material'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Delete'),
        ),
      );
      await tester.pumpAndSettle();

      expect(harness.materialService.deletedIds, <int>[1]);
    });

    testWidgets('Move to folder opens the existing folder picker', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      await tester.tap(find.byTooltip(_moreOptions).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move to folder'));
      await tester.pumpAndSettle();

      expect(find.text('Move to Folder'), findsOneWidget);
    });
  });
}
