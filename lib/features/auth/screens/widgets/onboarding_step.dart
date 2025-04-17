import 'package:flutter/material.dart';
import 'package:wyld/core/constants/app_colors.dart';
import 'package:wyld/shared/widgets/onboarding_progress_indicator.dart';

class OnboardingStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final double progress;
  final VoidCallback onNext;
  final String buttonText;
  final bool isLastStep;

  const OnboardingStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.progress,
    required this.onNext,
    this.buttonText = 'Next',
    this.isLastStep = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OnboardingProgressIndicator(step: progress),
              const SizedBox(height: 20),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primaryWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryWhite,
                ),
              ),
              const SizedBox(height: 30),
              Expanded(child: child),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: AppColors.primaryPink,
                  ),
                  child: Text(buttonText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
