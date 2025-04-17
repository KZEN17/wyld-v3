// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wyld/core/constants/app_colors.dart';
import 'package:wyld/features/auth/controllers/onboarding_controller.dart';
import 'package:wyld/features/auth/screens/widgets/onboarding_appbar.dart';

class LookingForStep extends ConsumerStatefulWidget {
  final Function onNext;

  const LookingForStep({super.key, required this.onNext});

  @override
  ConsumerState<LookingForStep> createState() => _LookingForStepState();
}

class _LookingForStepState extends ConsumerState<LookingForStep> {
  String? selectedOption;
  final List<Map<String, dynamic>> options = [
    {
      'title': 'Host a table',
      'subtitle': 'Find friends to share tables with.',
      'image': 'assets/host.png',
      'value': 'Host',
    },
    {
      'title': 'Join a table',
      'subtitle': 'Find a table and join the party',
      'image': 'assets/join.png',
      'value': 'Join',
    },
    {
      'title': 'I\'m not sure yet',
      'subtitle': 'Don\'t worry, you\'ll figure it out eventually',
      'image': 'assets/not-sure.png',
      'value': 'Not Sure',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with any existing selection
    final currentSelection = ref.read(onboardingControllerProvider).lookingFor;
    if (currentSelection.isNotEmpty) {
      selectedOption = currentSelection;
    }
  }

  void _selectOption(String option) {
    setState(() {
      selectedOption = option;
    });
    ref.read(onboardingControllerProvider.notifier).setLookingFor(option);
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
                value: 0.8,
                backgroundColor: AppColors.secondaryBackground,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryPink,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What are you looking to do?',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        color: AppColors.primaryWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Expanded(
                      child: ListView.builder(
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options[index];
                          final isSelected = selectedOption == option['value'];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _buildOptionCard(
                              title: option['title'],
                              subtitle: option['subtitle'],
                              image: option['image'],
                              value: option['value'],
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
                  onPressed:
                      selectedOption != null ? () => widget.onNext() : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primaryPink,
                    disabledBackgroundColor: AppColors.primaryPink.withOpacity(
                      0.5,
                    ),
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

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required String image,
    required String value,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _selectOption(value),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: AssetImage(image),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.1),
              BlendMode.darken,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  color:
                      isSelected ? AppColors.primaryPink : Colors.transparent,
                ),
                child:
                    isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
