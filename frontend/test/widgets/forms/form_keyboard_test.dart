import 'dart:io';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/ai/scan_document_result.dart';
import 'package:mobile/screens/auth/forgot_password_screen.dart';
import 'package:mobile/screens/auth/guest_setup_screen.dart';
import 'package:mobile/screens/auth/signin_screen.dart';
import 'package:mobile/screens/auth/signup_screen.dart';
import 'package:mobile/screens/profile/change_password_screen.dart';
import 'package:mobile/screens/scan/scan_result_screen.dart';
import 'package:mobile/utils/form_keyboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Forms whose keyboard behaviour is checked. Their scroll views use
/// FormKeyboard.dismissBehavior.
final Map<String, Widget Function()> _forms = <String, Widget Function()>{
  'Sign in': () => const SignInScreen(),
  'Sign up': () => const SignUpScreen(),
  'Forgot password': () => const ForgotPasswordScreen(),
  'Guest setup': () => const GuestSetupScreen(),
  'Change password': () => const ChangePasswordScreen(),
};

const double _phoneWidth = 320;
const double _phoneHeight = 568;
const double _keyboardHeight = 260;

Future<void> _pumpForm(
  WidgetTester tester,
  Widget screen, {
  double textScale = 1,
  bool keyboard = false,
}) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(_phoneWidth * 3, _phoneHeight * 3);
  tester.view.viewInsets = keyboard
      ? const FakeViewPadding(bottom: _keyboardHeight * 3)
      : FakeViewPadding.zero;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: screen,
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

bool _hasFocus(WidgetTester tester, Finder field) {
  return tester.widget<EditableText>(field).focusNode.hasFocus;
}

/// The page margin, left of every field and button: a tap here lands on
/// the form's background.
const Offset _background = Offset(4, 300);

/// Field [index], scrolled into view. On a small phone some fields start
/// below the visible area, and lists build them only when scrolled near.
Future<Finder> _revealField(WidgetTester tester, int index) async {
  final Finder anyField = find.byType(EditableText, skipOffstage: false);
  final Finder scrollable = find.byType(Scrollable).first;

  // At 2x text a tall header can push the form out of the built area.
  for (int step = 0; step < 20 && anyField.evaluate().isEmpty; step++) {
    await tester.drag(scrollable, const Offset(0, -120));
    await tester.pumpAndSettle();
  }

  final Finder field = find.byType(EditableText, skipOffstage: false).at(index);
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();

  return field;
}

/// The keyboard action of every field, in screen order.
List<TextInputAction?> _keyboardActions(WidgetTester tester) {
  return tester
      .widgetList<EditableText>(find.byType(EditableText, skipOffstage: false))
      .map((EditableText field) => field.textInputAction)
      .toList();
}

/// Expected actions: Next on every field except the last, Done on the last.
List<TextInputAction> _nextThenDone(int count) => <TextInputAction>[
  for (int index = 0; index < count - 1; index++) TextInputAction.next,
  TextInputAction.done,
];

/// The keyboard action each form must show, field by field.
final Map<String, List<TextInputAction>> _formActions =
    <String, List<TextInputAction>>{
      'Sign in': _nextThenDone(2),
      'Sign up': _nextThenDone(5),
      // The first step shows only the email field.
      'Forgot password': _nextThenDone(1),
      'Guest setup': _nextThenDone(1),
      'Change password': _nextThenDone(3),
    };

/// A source file's text with \n line endings (a Windows checkout has
/// \r\n).
String _source(File file) => file.readAsStringSync().replaceAll('\r\n', '\n');

Future<Finder> _focusFirstField(WidgetTester tester) async {
  final Finder field = await _revealField(tester, 0);

  await tester.tap(field);
  await tester.pump();
  expect(_hasFocus(tester, field), isTrue);

  return field;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('scrolling a form never closes the keyboard', () {
    expect(
      FormKeyboard.dismissBehavior,
      ScrollViewKeyboardDismissBehavior.manual,
    );
    expect(FormKeyboard.closeOnTapOutside, isFalse);
  });

  for (final MapEntry<String, Widget Function()> form in _forms.entries) {
    group(form.key, () {
      testWidgets('a tap on the background keeps the keyboard', (
        WidgetTester tester,
      ) async {
        await _pumpForm(tester, form.value());
        final Finder field = await _focusFirstField(tester);

        await tester.tapAt(_background);
        await tester.pump(const Duration(milliseconds: 300));
        expect(_hasFocus(tester, field), isTrue);
      });

      testWidgets('a tap that slides a little keeps the keyboard', (
        WidgetTester tester,
      ) async {
        // The reported problem: a finger that moves a few pixels while
        // tapping counted as a drag and closed the keyboard.
        await _pumpForm(tester, form.value());
        final Finder field = await _focusFirstField(tester);

        final TestGesture gesture = await tester.startGesture(
          _background,
          kind: PointerDeviceKind.touch,
        );
        await gesture.moveBy(const Offset(0, -6));
        await gesture.moveBy(const Offset(0, -6));
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 300));

        expect(_hasFocus(tester, field), isTrue);
      });

      testWidgets('scrolling the form keeps the keyboard', (
        WidgetTester tester,
      ) async {
        await _pumpForm(tester, form.value(), keyboard: true);
        final Finder field = await _focusFirstField(tester);

        await tester.dragFrom(_background, const Offset(0, -150));
        await tester.pump(const Duration(milliseconds: 300));

        expect(_hasFocus(tester, field), isTrue);
      });

      testWidgets(
        'every field stays above the keyboard on a small phone at 2x text',
        (WidgetTester tester) async {
          await _pumpForm(tester, form.value(), textScale: 2, keyboard: true);

          await _revealField(tester, 0);
          final int count = find
              .byType(EditableText, skipOffstage: false)
              .evaluate()
              .length;
          expect(count, greaterThan(0));

          for (int index = 0; index < count; index++) {
            final Finder field = await _revealField(tester, index);

            await tester.showKeyboard(field);
            await tester.pumpAndSettle(const Duration(milliseconds: 100));

            final Rect rect = tester.getRect(field);
            expect(
              rect.bottom,
              lessThanOrEqualTo(_phoneHeight - _keyboardHeight),
              reason: '${form.key}, field ${index + 1} is under the keyboard',
            );
            expect(rect.top, greaterThanOrEqualTo(0));
          }

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('Next on every field except the last, Done on the last', (
        WidgetTester tester,
      ) async {
        // A tall screen, so every field is built.
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(400, 3000);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(MaterialApp(home: form.value()));
        await tester.pump(const Duration(seconds: 1));

        expect(_keyboardActions(tester), _formActions[form.key]);
      });
    });
  }

  group('error text under the last field stays above the keyboard', () {
    // Forms that show errors under their fields. Sign in and sign up show
    // errors as messages instead.
    final Map<String, (Widget Function(), String)> errorForms =
        <String, (Widget Function(), String)>{
          'Forgot password': (
            () => const ForgotPasswordScreen(),
            'Enter your registered email address.',
          ),
          'Change password': (
            () => const ChangePasswordScreen(),
            'Confirm your new password.',
          ),
        };

    for (final MapEntry<String, (Widget Function(), String)> form
        in errorForms.entries) {
      testWidgets('${form.key}, small phone, 2x text', (
        WidgetTester tester,
      ) async {
        final (Widget Function() screen, String error) = form.value;
        await _pumpForm(tester, screen(), textScale: 2, keyboard: true);

        await _revealField(tester, 0);
        final int count = find
            .byType(EditableText, skipOffstage: false)
            .evaluate()
            .length;

        // Submit the empty form from the last field: errors appear.
        Finder field = await _revealField(tester, count - 1);
        await tester.showKeyboard(field);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(find.text(error), findsOneWidget);

        // Scroll back until the last field sits just under the keyboard,
        // then go to it to fix it. Focusing scrolls only as far as
        // scrollPadding asks, so this checks that the error under it comes
        // into view too.
        const double keyboardTop = _phoneHeight - _keyboardHeight;
        final ScrollPosition position = tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position;
        position.jumpTo(
          position.pixels - (keyboardTop - tester.getRect(field).top + 8),
        );
        await tester.pumpAndSettle();
        expect(tester.getRect(field).top, greaterThan(keyboardTop));

        await tester.showKeyboard(field);
        await tester.pumpAndSettle(const Duration(milliseconds: 100));

        expect(tester.getRect(field).bottom, lessThanOrEqualTo(keyboardTop));
        expect(
          tester.getRect(find.text(error)).bottom,
          lessThanOrEqualTo(keyboardTop),
          reason: 'the error under the last field is under the keyboard',
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('form dialogs', () {
    testWidgets('Save to Materials stays open after a tap outside', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      const DocumentBlock block = DocumentBlock(
        id: 0,
        order: 1,
        type: 'text',
        rawContent: 'Solve for x.',
        normalizedContent: 'Solve for x.',
        boundingBox: <double>[],
        polygonPoints: <List<double>>[],
        isText: true,
        isFormula: false,
        isTable: false,
        tableRows: <List<String>>[],
        brailleContent: '⠠⠎⠕⠇⠧⠑⠀⠿⠀⠰⠭⠲',
        brailleCode: 'ueb',
        brailleSuccess: true,
        brailleError: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ScanResultScreen(
            result: const ScanDocumentResult(
              model: 'test',
              pipelineVersion: 'test',
              device: 'test',
              pageCount: 1,
              processingTimeMs: 1,
              blocks: <DocumentBlock>[block],
              pages: <DocumentPage>[
                DocumentPage(
                  pageIndex: 0,
                  width: 0,
                  height: 0,
                  blocks: <DocumentBlock>[block],
                ),
              ],
            ),
            scannedImage: File('missing-test-image.png'),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      // The result screen's entrance animation never settles here (the
      // test image is missing), so press the button directly; this test is
      // about the dialog.
      final FilledButton saveButton = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Save to Materials'),
          matching: find.byWidgetPredicate((Widget w) => w is FilledButton),
        ),
      );
      saveButton.onPressed!();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Save as Material'), findsOneWidget);

      // Title and subject: Next. Description is several lines, so its
      // key adds a new line (the Save button saves).
      expect(_keyboardActions(tester), <TextInputAction>[
        TextInputAction.next,
        TextInputAction.next,
        TextInputAction.newline,
      ]);

      final Finder titleField = find.byType(EditableText).first;
      expect(titleField, findsOneWidget);

      await tester.enterText(titleField, 'Fractions worksheet');
      await tester.tapAt(const Offset(8, 8));
      await tester.pump(const Duration(seconds: 1));

      // Still open, with the typed text.
      expect(find.text('Save as Material'), findsOneWidget);
      expect(find.text('Fractions worksheet'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(find.text('Save as Material'), findsNothing);
    });

    test('History rename, Materials folder and the guest nickname sheet '
        'use the shared setting', () {
      // These screens load data from services, so the wiring is checked
      // in the source; Save to Materials above is the same pattern tested
      // end to end.
      String read(String path) => _source(File(path));

      final String history = read('lib/screens/history/history_screen.dart');
      expect(
        history,
        contains(
          'await _showAnimatedDialog<String>(\n'
          '      // A tap outside must not throw away a half-typed title.\n'
          '      barrierDismissible: FormKeyboard.closeOnTapOutside,',
        ),
      );

      expect(
        read('lib/screens/materials/material_screen.dart'),
        contains(
          'showGeneralDialog<String>(\n'
          '      context: context,\n'
          '      // A tap outside must not throw away a half-typed folder name.\n'
          '      barrierDismissible: FormKeyboard.closeOnTapOutside,',
        ),
      );

      expect(
        read('lib/screens/profile/account_information_screen.dart'),
        contains('isDismissible: FormKeyboard.closeOnTapOutside,'),
      );
    });

    test('the folder name field shows Done', () {
      expect(
        _source(File('lib/screens/materials/material_screen.dart')),
        contains(
          'textCapitalization: TextCapitalization.words,\n'
          '                // The only field: Done creates the folder.\n'
          '                textInputAction: TextInputAction.done,',
        ),
      );
    });

    test('every form field keeps its error text above the keyboard', () {
      // Search fields sit at the top of their screen and show no errors.
      final RegExp field = RegExp(r'\b(TextField|TextFormField)\(');
      final Map<String, String> missing = <String, String>{};

      for (final File file
          in Directory('lib/screens')
              .listSync(recursive: true)
              .whereType<File>()
              .where((File file) => file.path.endsWith('.dart'))) {
        final String source = _source(file);
        final int fields = field.allMatches(source).length;
        final int search = 'TextInputAction.search'.allMatches(source).length;
        final int padded = 'scrollPadding: FormKeyboard.scrollPadding'
            .allMatches(source)
            .length;

        if (padded != fields - search) {
          missing[file.path] = '$padded of ${fields - search}';
        }
      }

      expect(missing, isEmpty);
    });

    test('sign-up uses the shared keyboard setting', () {
      expect(
        _source(File('lib/screens/auth/signup_screen.dart')),
        contains('keyboardDismissBehavior: FormKeyboard.dismissBehavior,'),
      );
    });

    test('no form scroll view closes the keyboard on drag', () {
      final List<String> offenders = Directory('lib/screens')
          .listSync(recursive: true)
          .whereType<File>()
          .where((File file) => file.path.endsWith('.dart'))
          .where(
            (File file) => _source(
              file,
            ).contains('ScrollViewKeyboardDismissBehavior.onDrag'),
          )
          .map((File file) => file.path)
          .toList();

      expect(offenders, isEmpty);
    });
  });
}
