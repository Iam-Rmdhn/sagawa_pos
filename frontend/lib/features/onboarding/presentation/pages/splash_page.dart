import 'package:flutter/material.dart';
import 'package:sagawa_pos/core/constants/app_constants.dart';
import 'package:sagawa_pos/data/services/user_service.dart';
import 'package:sagawa_pos/features/home/presentation/pages/home_page.dart';
import 'package:sagawa_pos/features/auth/presentation/pages/login_page.dart';
import 'package:sagawa_pos/features/onboarding/presentation/pages/welcome_page.dart';
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
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool(_firstTimeKey) ?? true;

    final isLoggedIn = await UserService.isLoggedIn();

    if (isFirstTime) {
      await prefs.setBool(_firstTimeKey, false);
      if (!mounted) return;
      _navigateToPage(const WelcomePage());
    } else if (isLoggedIn) {
      if (!mounted) return;
      _navigateToPage(const HomePage());
    } else {
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
