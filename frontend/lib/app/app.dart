import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sagawa_pos_new/core/theme/app_theme.dart';
import 'package:sagawa_pos_new/features/home/presentation/bloc/home_cubit.dart';
import 'package:sagawa_pos_new/features/onboarding/presentation/pages/welcome_page.dart';

class SagawaPosApp extends StatelessWidget {
  const SagawaPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeCubit>(create: (_) => HomeCubit()..loadMockProducts()),
      ],
      child: MaterialApp(
        title: 'Sagawa POS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const WelcomePage(),
      ),
    );
  }
}
