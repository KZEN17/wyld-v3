import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wyld/core/constants/app_colors.dart';
import 'package:wyld/features/auth/controllers/auth_controller.dart';
import 'package:wyld/features/auth/controllers/onboarding_controller.dart';

import 'widgets/steps/steps.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _initializedSteps = false;

  @override
  void initState() {
    super.initState();
    // Initialize controller to start at photos step
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initializedSteps) {
        // Set initial step directly to addPhotos
        ref
            .read(onboardingControllerProvider.notifier)
            .goToStep(OnboardingStepType.addPhotos);
        _initializedSteps = true;
      }
    });
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingControllerProvider);
    final authState = ref.watch(authControllerProvider);

    // Handle loading and error states from auth
    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authState.hasError) {
      return Scaffold(body: Center(child: Text('Error: ${authState.error}')));
    }

    final user = authState.value;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in. Please login first.')),
      );
    }

    // If loading, show loading indicator
    if (onboardingState.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.primaryBackground,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPink),
          ),
        ),
      );
    }

    // Render the appropriate step based on the current state
    switch (onboardingState.currentStep) {
      case OnboardingStepType.email:
      case OnboardingStepType.phoneVerification:
      case OnboardingStepType.username:
        // Just show a loading screen while we transition to the photos step
        return const Scaffold(
          backgroundColor: AppColors.primaryBackground,
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPink),
            ),
          ),
        );

      case OnboardingStepType.addPhotos:
        return PhotosStep(
          onNext: () {
            ref.read(onboardingControllerProvider.notifier).nextStep();
          },
        );

      case OnboardingStepType.bio:
        return BioStep(
          onNext: () {
            ref.read(onboardingControllerProvider.notifier).nextStep();
          },
        );

      case OnboardingStepType.gender:
        return GenderStep(
          onNext: () {
            ref.read(onboardingControllerProvider.notifier).nextStep();
          },
        );

      case OnboardingStepType.lookingFor:
        return LookingForStep(
          onNext: () {
            ref.read(onboardingControllerProvider.notifier).nextStep();
          },
        );

      case OnboardingStepType.location:
        return PermissionsStep(
          onComplete: () {
            ref.read(onboardingControllerProvider.notifier).nextStep();
            _navigateToHome();
          },
        );

      case OnboardingStepType.complete:
        // Immediately navigate to home on completion
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToHome();
        });
        return const Scaffold(
          backgroundColor: AppColors.primaryBackground,
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPink),
            ),
          ),
        );
    }
  }
}
