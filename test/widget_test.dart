import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dreamin_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DreaminApp());

    // Verify that the app starts
    expect(find.text('Dreamin'), findsOneWidget);
  });
}
