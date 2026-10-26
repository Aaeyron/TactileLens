import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/models/materials/material_model.dart';
import 'package:mobile/screens/home/home_screen.dart';
import 'package:mobile/screens/main/tab_data_cache.dart';
import 'package:mobile/utils/session_manager.dart';

MaterialModel _material(int id, String title, String recognizedContent) {
  return MaterialModel(
    id: id,
    title: title,
    subject: 'General Algebra',
    description: '',
    fileName: '$title.pdf',
    fileType: 'application/pdf',
    fileSize: 1000,
    filePath: '',
    uploadDate: DateTime.now().subtract(Duration(hours: id)),
    recognizedContent: recognizedContent,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SessionManager.guestModeKey: true,
    });
  });

  testWidgets('recent materials say Math (Nemeth) or Text (UEB)', (
    WidgetTester tester,
  ) async {
    // Cached data is shown at once; the background refresh has no guest
    // database in tests and keeps it.
    final TabDataCache cache = TabDataCache()
      ..home = (
        displayName: 'Teacher',
        role: 'Educator',
        isGuest: true,
        materials: <MaterialModel>[
          _material(1, 'Equations', 'x^2 + 3x - 4 = 0'),
          _material(2, 'Reading', 'Read the passage below.'),
        ],
      );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          cache: cache,
          onScanPressed: () {},
          onMaterialsPressed: () {},
          onHistoryPressed: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Reading'),
      120,
      scrollable: find
          .byWidgetPredicate(
            (Widget widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );

    expect(find.text('Math (Nemeth)'), findsOneWidget);
    expect(find.text('Text (UEB)'), findsOneWidget);
    expect(find.textContaining('•'), findsNothing);
  });
}
