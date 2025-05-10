// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:empathy_hub_app/main.dart';

void main() {
  testWidgets('App initializes, shows loading, then HomePage after anonymous auth', (WidgetTester tester) async {
    // Set mock initial values for SharedPreferences for predictable testing.
    // Start with no stored ID, so a new one will be generated.
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(const EmpathyHubApp());

    // Initially, we should see the loading indicator from AuthGate
    // because AuthCubit emits AuthLoading first.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for all asynchronous operations to complete.
    // This includes the Future.delayed in AuthCubit and SharedPreferences calls.
    // pumpAndSettle will keep pumping frames until there are no more frames scheduled.
    await tester.pumpAndSettle();

    // After loading, the CircularProgressIndicator should be gone.
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Now, we should be on the HomePage.
    // Let's verify some text from the HomePage.
    // We expect the AppBar title to contain "Empathy Hub - Welcome Anonymous User"
    // and part of an ID. We can use a partial match.
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.textContaining(RegExp(r'Empathy Hub - Welcome Anonymous User \([a-f0-9]{8}...\)')),
      ),
      findsOneWidget,
    );

    // And the body text
    expect(find.text('Main App Content Goes Here!'), findsOneWidget);
  });
}
