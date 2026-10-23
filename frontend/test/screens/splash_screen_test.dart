import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/screens/auth/auth_screen.dart';
import 'package:mobile/screens/splash/splash_screen.dart';
import 'package:mobile/utils/session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

const MethodChannel _secureStorage = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

const Duration _minimum = Duration(milliseconds: 1500);
const Duration _maximum = Duration(seconds: 5);

/// Time for the route to the next screen to finish.
const Duration _routeTime = Duration(seconds: 1);

class _ReplaceCounter extends NavigatorObserver {
  int replacements = 0;

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    replacements++;
  }
}

Widget _destination(SplashDestination destination) =>
    Text('opened ${destination.name}');

Future<_ReplaceCounter> _pumpSplash(
  WidgetTester tester, {
  Future<SplashDestination> Function()? load,
  bool realDestinations = false,
}) async {
  final _ReplaceCounter counter = _ReplaceCounter();

  await tester.pumpWidget(
    MaterialApp(
      navigatorObservers: <NavigatorObserver>[counter],
      home: SplashScreen(
        loadDestination: load ?? SplashScreen.loadSavedDestination,
        buildDestination: realDestinations
            ? SplashScreen.buildDestinationScreen
            : _destination,
      ),
    ),
  );

  return counter;
}

/// Makes every secure storage call fail, or never answer.
void _secureStorageReplies(Future<Object?>? Function(MethodCall call) reply) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_secureStorage, reply);
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorage, null),
  );
}

void main() {
  setUp(() {
    // A signed-in user, so the session check reaches secure storage.
    SharedPreferences.setMockInitialValues(<String, Object>{
      SessionManager.userIdKey: 7,
    });
  });

  testWidgets('shows only the logo and "TactileLens", read once', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final Completer<SplashDestination> never = Completer<SplashDestination>();

    await _pumpSplash(tester, load: () => never.future);
    await tester.pump();

    expect(find.text('Get Started'), findsNothing);
    expect(find.byType(ButtonStyleButton), findsNothing);
    expect(find.byType(InkWell), findsNothing);
    expect(find.text('TactileLens'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    expect(find.bySemanticsLabel('TactileLens'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('logo')), findsNothing);
    // Nothing TalkBack can focus as a button.
    expect(find.semantics.byAction(SemanticsAction.tap), findsNothing);
    expect(find.semantics.byFlag(SemanticsFlag.isButton), findsNothing);

    // Let the guard run out so no timer is left behind.
    await tester.pump(_maximum + _routeTime);
    semantics.dispose();
  });

  testWidgets('waits the minimum time, then moves on by itself', (
    WidgetTester tester,
  ) async {
    final _ReplaceCounter counter = await _pumpSplash(
      tester,
      load: () async => SplashDestination.auth,
    );

    await tester.pump(_minimum - const Duration(milliseconds: 100));
    expect(find.text('opened auth'), findsNothing);
    expect(counter.replacements, 0);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(_routeTime);

    expect(find.text('opened auth'), findsOneWidget);
    expect(find.text('TactileLens'), findsNothing);
    expect(counter.replacements, 1);
  });

  testWidgets('a guest or signed-in session opens the main screen', (
    WidgetTester tester,
  ) async {
    await _pumpSplash(tester, load: () async => SplashDestination.main);

    await tester.pump(_minimum);
    await tester.pump(_routeTime);

    expect(find.text('opened main'), findsOneWidget);
  });

  testWidgets('a failing session check opens AuthScreen', (
    WidgetTester tester,
  ) async {
    _secureStorageReplies(
      (MethodCall call) =>
          throw PlatformException(code: 'keystore', message: 'broken'),
    );

    final _ReplaceCounter counter = await _pumpSplash(
      tester,
      realDestinations: true,
    );

    await tester.pump(_minimum);
    await tester.pump(_routeTime);

    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    expect(counter.replacements, 1);
  });

  testWidgets('a session check that never answers opens AuthScreen at '
      'the guard time', (WidgetTester tester) async {
    _secureStorageReplies((MethodCall call) => Completer<Object?>().future);

    final _ReplaceCounter counter = await _pumpSplash(
      tester,
      realDestinations: true,
    );

    await tester.pump(_maximum - const Duration(milliseconds: 100));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(counter.replacements, 0);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(_routeTime);

    expect(find.byType(AuthScreen), findsOneWidget);
    expect(counter.replacements, 1);
  });

  testWidgets('navigates exactly once', (WidgetTester tester) async {
    final _ReplaceCounter counter = await _pumpSplash(
      tester,
      load: () async => SplashDestination.auth,
    );

    await tester.pump(_maximum * 2);
    await tester.pump(_routeTime);

    expect(counter.replacements, 1);
    expect(find.text('opened auth'), findsOneWidget);
  });

  testWidgets('never navigates after the splash is gone', (
    WidgetTester tester,
  ) async {
    final Completer<SplashDestination> load = Completer<SplashDestination>();
    final _ReplaceCounter counter = await _pumpSplash(
      tester,
      load: () => load.future,
    );

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(const SizedBox());

    load.complete(SplashDestination.main);
    await tester.pump(_maximum * 2);

    expect(counter.replacements, 0);
    expect(tester.takeException(), isNull);
  });
}
