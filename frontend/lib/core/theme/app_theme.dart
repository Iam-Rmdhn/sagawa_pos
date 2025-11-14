import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralizes theme configuration so it can be shared across MaterialApp instances.
class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEF5350)),
      useMaterial3: true,
    );

    return base.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme),
      scaffoldBackgroundColor: Colors.white,
    );
  }
}
