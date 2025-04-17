import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wyld/core/constants/app_colors.dart';
import 'package:wyld/features/auth/controllers/onboarding_controller.dart';
import 'package:wyld/features/auth/screens/widgets/onboarding_appbar.dart';

import '../../../../../shared/widgets/widgets.dart';

class BioStep extends ConsumerStatefulWidget {
  final Function onNext;

  const BioStep({super.key, required this.onNext});

  @override
  ConsumerState<BioStep> createState() => _BioStepState();
}

class _BioStepState extends ConsumerState<BioStep> {
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with any existing bio
    final currentBio = ref.read(onboardingControllerProvider).bio;
    if (currentBio.isNotEmpty) {
      _bioController.text = currentBio;
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  void _saveBioAndContinue() {
    if (_bioController.text.isNotEmpty) {
      ref
          .read(onboardingControllerProvider.notifier)
          .setBio(_bioController.text);
      widget.onNext();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please add a bio')));
    }
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: LinearProgressIndicator(
                value: 0.6,
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
                      'Tell us about yourself',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        color: AppColors.primaryWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Write a short bio so others can get to know you better',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.secondaryWhite,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: StyledFormField(
                        controller: _bioController,
                        hintText: 'Tell us about yourself...',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please add a bio';
                          }
                          return null;
                        },
                        maxLines: 8,
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
                  onPressed: _saveBioAndContinue,
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
}
