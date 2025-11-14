// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sagawa_pos_new/app/app.dart';
import 'package:sagawa_pos_new/features/onboarding/presentation/pages/splash_page.dart';
import 'package:sagawa_pos_new/features/onboarding/presentation/pages/welcome_page.dart';

void main() {
  testWidgets('Sagawa POS boots to splash then welcome page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SagawaPosApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(SplashPage), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomePage), findsOneWidget);
  });
}
