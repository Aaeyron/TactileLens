import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/braille/braille_mode.dart';
import 'package:mobile/services/braille/offline_braille_service.dart';

const MethodChannel _channel = MethodChannel('com.tactilelens.app/liblouis');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> calls = <MethodCall>[];
  Object? Function(MethodCall call)? respond;

  setUp(() {
    calls.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (MethodCall call) async {
          calls.add(call);
          return respond?.call(call);
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    respond = null;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  test('a Braille 2 block sends no mode, exactly as before', () async {
    respond = (MethodCall call) => <String, Object?>{
      'success': true,
      'code': 'ueb',
      'content': '⠮',
      'error': null,
    };

    await const OfflineBrailleService().translateBlock('the', isFormula: false);

    expect(calls.single.method, 'translateBlock');
    expect(calls.single.arguments, <String, Object>{
      'content': 'the',
      'isFormula': false,
      'isTable': false,
    });
  });

  test('a Braille 1 block sends the uncontracted mode', () async {
    respond = (MethodCall call) => <String, Object?>{
      'success': true,
      'code': 'ueb',
      'content': '⠞⠓⠑',
      'error': null,
    };

    await const OfflineBrailleService().translateBlock(
      'the',
      isFormula: false,
      mode: BrailleMode.uncontracted,
    );

    expect(
      (calls.single.arguments as Map<Object?, Object?>)['brailleMode'],
      'uncontracted',
    );
  });

  test('lines are translated in one call, one result per line', () async {
    respond = (MethodCall call) => <String, Object?>{
      'results': <Object?>[
        <String, Object?>{'success': true, 'content': '⠞⠓⠑', 'error': null},
        <String, Object?>{'success': true, 'content': '⠏⠑⠕⠏⠇⠑', 'error': null},
      ],
    };

    final List<OfflineBrailleResult> results =
        await const OfflineBrailleService().translateUebLines(<String>[
          'the',
          'people',
        ], mode: BrailleMode.uncontracted);

    expect(calls, hasLength(1));
    expect(calls.single.method, 'translateTexts');
    expect(calls.single.arguments, <String, Object>{
      'contents': <String>['the', 'people'],
      'brailleMode': 'uncontracted',
    });
    expect(results.map((OfflineBrailleResult r) => r.content), <String>[
      '⠞⠓⠑',
      '⠏⠑⠕⠏⠇⠑',
    ]);
    expect(results.every((OfflineBrailleResult r) => r.code == 'ueb'), isTrue);
  });

  test('a native failure is reported so the caller can keep Braille 2', () {
    respond = (MethodCall call) {
      throw PlatformException(code: 'LIBLOUIS_ERROR', message: 'No table');
    };

    expect(
      const OfflineBrailleService().translateUebLines(<String>[
        'the',
      ], mode: BrailleMode.uncontracted),
      throwsA(isA<OfflineBrailleException>()),
    );
  });

  test('an incomplete response is reported as a failure', () {
    respond = (MethodCall call) => <String, Object?>{'results': <Object?>[]};

    expect(
      const OfflineBrailleService().translateUebLines(<String>[
        'the',
      ], mode: BrailleMode.uncontracted),
      throwsA(isA<OfflineBrailleException>()),
    );
  });

  test('other platforms report that translation is unavailable', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    expect(
      const OfflineBrailleService().translateUebLines(<String>[
        'the',
      ], mode: BrailleMode.uncontracted),
      throwsA(isA<OfflineBrailleException>()),
    );
    expect(calls, isEmpty);
  });

  test('unknown or missing stored modes mean Braille 2', () {
    expect(BrailleMode.fromWireName(null), BrailleMode.contracted);
    expect(BrailleMode.fromWireName('grade3'), BrailleMode.contracted);
    expect(BrailleMode.fromWireName('uncontracted'), BrailleMode.uncontracted);
  });
}
