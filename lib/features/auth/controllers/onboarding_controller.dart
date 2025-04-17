// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wyld/features/auth/controllers/auth_controller.dart';

// Enum to represent different onboarding steps
enum OnboardingStepType {
  email,
  phoneVerification,
  username,
  addPhotos,
  bio,
  gender, // New step added here
  lookingFor,
  location,
  complete,
}

// State class for onboarding
class OnboardingState {
  final OnboardingStepType currentStep;
  final String email;
  final String phoneNumber;
  final String username;
  final List<File> photos;
  final String bio;
  final String gender;
  final String lookingFor;
  final double latitude;
  final double longitude;
  final bool isLoading;

  OnboardingState({
    this.currentStep = OnboardingStepType.email,
    this.email = '',
    this.phoneNumber = '',
    this.username = '',
    this.photos = const [],
    this.bio = '',
    this.gender = 'Male',
    this.lookingFor = 'Host',
    this.latitude = 0,
    this.longitude = 0,
    this.isLoading = false,
  });

  OnboardingState copyWith({
    OnboardingStepType? currentStep,
    String? email,
    String? phoneNumber,
    String? username,
    List<File>? photos,
    String? bio,
    String? gender,
    String? lookingFor,
    double? latitude,
    double? longitude,
    bool? isLoading,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      username: username ?? this.username,
      photos: photos ?? this.photos,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      lookingFor: lookingFor ?? this.lookingFor,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Controller class for onboarding
class OnboardingController extends StateNotifier<OnboardingState> {
  final Ref _ref;
  final AuthController _authController;

  OnboardingController(this._ref, this._authController)
    : super(OnboardingState());

  void setEmail(String email) {
    state = state.copyWith(email: email);
  }

  void setPhoneNumber(String phoneNumber) {
    state = state.copyWith(phoneNumber: phoneNumber);
  }

  void setUsername(String username) {
    state = state.copyWith(username: username);
  }

  void addPhotos(List<File> photos) {
    state = state.copyWith(photos: [...state.photos, ...photos]);
  }

  void removePhoto(int index) {
    final newPhotos = List<File>.from(state.photos);
    newPhotos.removeAt(index);
    state = state.copyWith(photos: newPhotos);
  }

  void setBio(String bio) {
    state = state.copyWith(bio: bio);
  }

  void setGender(String gender) {
    state = state.copyWith(gender: gender);
  }

  void setLookingFor(String lookingFor) {
    state = state.copyWith(lookingFor: lookingFor);
  }

  void setLocation(double latitude, double longitude) {
    state = state.copyWith(latitude: latitude, longitude: longitude);
  }

  void nextStep() {
    final nextStepIndex =
        OnboardingStepType.values.indexOf(state.currentStep) + 1;
    if (nextStepIndex < OnboardingStepType.values.length) {
      state = state.copyWith(
        currentStep: OnboardingStepType.values[nextStepIndex],
      );
    }
  }

  void goToStep(OnboardingStepType step) {
    state = state.copyWith(currentStep: step);
  }

  // Complete the onboarding process
  Future<void> completeOnboarding(
    BuildContext context, {
    double? latitude,
    double? longitude,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      // Get the current user from the authControllerProvider
      final authState = _ref.read(authControllerProvider);
      final user = authState.value;

      if (user != null) {
        // Set the location if provided
        if (latitude != null && longitude != null) {
          state = state.copyWith(latitude: latitude, longitude: longitude);
        }

        // Create a full updated user model with all changes
        final updatedUser = user.copyWith(
          bio: state.bio,
          gender: state.gender,
          lookingFor: state.lookingFor,
          latitude: state.latitude,
          longitude: state.longitude,
          profileComplete: true,
        );

        // First upload the images if any
        if (state.photos.isNotEmpty) {
          final userWithImages = await _authController.uploadProfileImages(
            userModel: updatedUser,
            imageFiles: state.photos,
            context: context,
          );

          // Now do a final update with ALL the data
          await _authController.updateUserProfile(
            userModel: userWithImages,
            context: context,
            navigateToHome: true,
          );
        } else {
          // If no images to upload, just update the profile
          await _authController.updateUserProfile(
            userModel: updatedUser,
            context: context,
            navigateToHome: true,
          );
        }
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error completing profile: $e')));
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

// Provider for the onboarding controller
final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
      final authController = ref.watch(authControllerProvider.notifier);
      return OnboardingController(ref, authController);
    });
