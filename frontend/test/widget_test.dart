import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/screens/auth/auth_screen.dart';
import 'package:mobile/screens/splash/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App loads: splash, then sign in by itself', (
    WidgetTester tester,
  ) async {
    // No saved session, and secure storage holds no token.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (MethodCall call) async => null,
        );

    await tester.pumpWidget(const TactileLensApp());

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('TactileLens'), findsOneWidget);
    expect(find.text('Get Started'), findsNothing);
    expect(find.byType(ButtonStyleButton), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(AuthScreen), findsOneWidget);
  });
}
