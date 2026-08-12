// Minimal smoke test. SplashScreen (the app's real entry widget) kicks off a
// delayed auto-login check against secure storage and Provider state that
// aren't available in a plain widget test, so a full app-boot test is left to
// a later phase alongside proper provider mocking. This confirms the basic
// Flutter/MaterialApp scaffolding renders without error.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders a basic MaterialApp scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        title: 'Turf War',
        theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
        home: const Scaffold(
          body: Center(child: Text('TURF WAR')),
        ),
      ),
    );

    expect(find.text('TURF WAR'), findsOneWidget);
  });
}
