import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wyld/core/constants/app_colors.dart';
import 'package:wyld/core/constants/app_routes.dart';

import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/screens/landing_page.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/home/screens/home_screen.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return MaterialApp(
      title: 'WYLD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: AppColors.primaryBackground,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      // Home determines the initial screen
      home: authState.when(
        data: (user) {
          if (user == null) {
            return const LandingPage();
          }
          // If user exists but profile is not complete, go to onboarding
          return user.profileComplete
              ? const HomeScreen()
              : const OnboardingScreen();
        },
        loading:
            () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
        error: (_, __) => const LandingPage(),
      ),
      // Routes for navigation
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
