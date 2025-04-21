// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthController extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AsyncValue.loading()) {
    // Initialize by checking for current user
    checkCurrentUser();
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required BuildContext context,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Register the user
      final user = await _authRepository.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );

      // Update state with the new user
      state = AsyncValue.data(user);

      // Make sure to check current user to refresh the auth state
      await checkCurrentUser();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration successful! Let\'s complete your profile.',
          ),
        ),
      );

      // Navigate to onboarding
      Navigator.of(context).pushReplacementNamed('/onboarding');
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
    }
  }

  Future<void> login({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.login(
        email: email,
        password: password,
      );
      state = AsyncValue.data(user);

      // Also make sure to check current user after login
      await checkCurrentUser();

      if (user != null && user.profileComplete) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      await _authRepository.logout();
      state = const AsyncValue.data(null);

      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    }
  }

  Future<void> checkCurrentUser() async {
    try {
      final user = await _authRepository.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
  Future<UserModel?> getUserById({
    required String userId,
    required BuildContext context,
  }) async {
    try {
      final user = await _authRepository.getUserById(userId);
      return user;
    } catch (e, stackTrace) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch user: $e')),
      );
      return null;
    }
  }

  Future<UserModel> uploadProfileImages({
    required UserModel userModel,
    required List<File> imageFiles,
    required BuildContext context,
  }) async {
    state = const AsyncValue.loading();
    try {
      final updatedUser = await _authRepository.uploadProfileImages(
        userModel: userModel,
        imageFiles: imageFiles,
      );

      state = AsyncValue.data(updatedUser);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile images uploaded successfully')),
      );

      return updatedUser;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
      rethrow;
    }
  }

  Future<UserModel> updateUserProfile({
    required UserModel userModel,
    required BuildContext context,
    bool navigateToHome = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final updatedUser = await _authRepository.updateUserProfile(userModel);
      state = AsyncValue.data(updatedUser);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

      // Optionally navigate to home if profile completion is done
      if (navigateToHome && updatedUser.profileComplete) {
        Navigator.of(context).pushReplacementNamed('/home');
      }

      return updatedUser;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Profile update failed: $e')));
      rethrow;
    }
  }
}
final userByIdProvider = FutureProvider.family<UserModel, String>((ref, userId) async {
  final authRepo = ref.read(authRepositoryProvider);
  return await authRepo.getUserById(userId);
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserModel?>>((ref) {
      final authRepository = ref.watch(authRepositoryProvider);
      return AuthController(authRepository);
    });

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.value != null;
});
