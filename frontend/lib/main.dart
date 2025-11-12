import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/di/dependency_injection.dart';
import 'core/services/supabase_service.dart';
import 'core/services/local_storage_service.dart';
import 'features/auth/presentation/pages/splash_screen.dart';
import 'features/auth/presentation/pages/login_screen.dart';
import 'features/products/presentation/pages/products_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (optional, tidak wajib untuk mock data)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('⚠️ .env file not found, using mock data mode');
  }

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
    debugPrint('✅ Supabase initialized successfully');
  } catch (e) {
    debugPrint('❌ Supabase initialization failed: $e');
  }

  // Initialize Local Storage
  try {
    await LocalStorageService.initialize();
    debugPrint('✅ Local Storage initialized successfully');
  } catch (e) {
    debugPrint('❌ Local Storage initialization failed: $e');
  }

  // Initialize dependencies
  // useMockData = true (di dependency_injection.dart)
  // Set ke false ketika database sudah siap
  DependencyInjection.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        BlocProvider(create: (_) => DependencyInjection.productBloc),
        BlocProvider(create: (_) => DependencyInjection.cartBloc),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ScreenUtilInit(
            designSize: const Size(375, 812),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) {
              return MaterialApp(
                title: 'Sagawa POS',
                debugShowCheckedModeBanner: false,
                themeMode: themeProvider.themeMode,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                initialRoute: '/',
                routes: {
                  '/': (context) => const SplashScreen(),
                  '/login': (context) => const LoginScreen(),
                  '/home': (context) => const ProductsPage(),
                },
              );
            },
          );
        },
      ),
    );
  }
}
