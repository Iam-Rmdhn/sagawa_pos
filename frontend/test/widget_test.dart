import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sagawa_pos_new/app/app.dart';
import 'package:sagawa_pos_new/features/onboarding/presentation/pages/splash_page.dart';
import 'package:sagawa_pos_new/features/onboarding/presentation/pages/welcome_page.dart';

void main() {
  testWidgets('Sagawa POS boots to splash then welcome page', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SagawaPosApp());
    expect(find.byType(MaterialApp), findsOneWidget);

    expect(find.byType(SplashPage), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomePage), findsOneWidget);
  });
}
