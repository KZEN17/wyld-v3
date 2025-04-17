import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wyld/core/constants/app_colors.dart';
import 'package:wyld/features/auth/controllers/onboarding_controller.dart';
import 'package:wyld/features/auth/screens/widgets/onboarding_appbar.dart';

class GenderStep extends ConsumerStatefulWidget {
  final Function onNext;

  const GenderStep({super.key, required this.onNext});

  @override
  ConsumerState<GenderStep> createState() => _GenderStepState();
}

class _GenderStepState extends ConsumerState<GenderStep> {
  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  String? selectedGender;

  @override
  void initState() {
    super.initState();
    // Initialize with any existing selection
    final currentGender = ref.read(onboardingControllerProvider).gender;
    if (currentGender.isNotEmpty) {
      selectedGender = currentGender;
    } else {
      selectedGender = _genderOptions[0]; // Default to first option
    }
  }

  void _selectGender(String gender) {
    setState(() {
      selectedGender = gender;
    });
    ref.read(onboardingControllerProvider.notifier).setGender(gender);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: const OnboardingAppbar(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: LinearProgressIndicator(
                value: 0.7, // Adjusted for new position
                backgroundColor: AppColors.secondaryBackground,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryPink,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What\'s your gender?',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        color: AppColors.primaryWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This helps us match you with the right people',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.secondaryWhite,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _genderOptions.length,
                        itemBuilder: (context, index) {
                          final option = _genderOptions[index];
                          final isSelected = selectedGender == option;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _buildGenderOption(
                              gender: option,
                              isSelected: isSelected,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (selectedGender != null) {
                      widget.onNext();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primaryPink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Next',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderOption({
    required String gender,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _selectGender(gender),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color:
              isSelected
                  ? AppColors.primaryPink.withValues(alpha: 0.2)
                  : AppColors.secondaryBackground,
          border: Border.all(
            color: isSelected ? AppColors.primaryPink : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              gender,
              style: TextStyle(
                color: AppColors.primaryWhite,
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryPink,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}
