import 'package:flutter/material.dart';
import 'package:sagawa_pos_new/core/constants/app_constants.dart';
import 'package:sagawa_pos_new/data/services/user_service.dart';
import 'package:sagawa_pos_new/features/home/presentation/pages/home_page.dart';
import 'package:sagawa_pos_new/features/auth/presentation/pages/login_page.dart';
import 'package:sagawa_pos_new/features/onboarding/presentation/pages/welcome_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const String _firstTimeKey = 'is_first_time';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait a bit to show splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check if this is the first time opening the app
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool(_firstTimeKey) ?? true;

    // Check if user is logged in
    final isLoggedIn = await UserService.isLoggedIn();

    if (isFirstTime) {
      // First time: Show welcome page and mark as not first time
      await prefs.setBool(_firstTimeKey, false);
      if (!mounted) return;
      _navigateToPage(const WelcomePage());
    } else if (isLoggedIn) {
      // Not first time and logged in: Go to home
      if (!mounted) return;
      _navigateToPage(const HomePage());
    } else {
      // Not first time but not logged in: Go to login
      if (!mounted) return;
      _navigateToPage(const LoginPage());
    }
  }

  void _navigateToPage(Widget page) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          AppImages.appLogo,
          width: 120,
          height: 120,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.store, size: 120, color: Color(0xFFFF4B4B));
          },
        ),
      ),
    );
  }
}
