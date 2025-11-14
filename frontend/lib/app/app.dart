import 'package:flutter/material.dart';
import 'package:sagawa_pos_new/core/theme/app_theme.dart';
import 'package:sagawa_pos_new/features/onboarding/presentation/pages/splash_page.dart';

class SagawaPosApp extends StatelessWidget {
  const SagawaPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sagawa POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashPage(),
    );
  }
}
