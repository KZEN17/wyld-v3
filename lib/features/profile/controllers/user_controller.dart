import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/models/user_model.dart';
import '../repositories/user_repository.dart';
import '../../auth/controllers/auth_controller.dart';

// Provider for user profile data
final userProfileProvider = FutureProvider.family<UserModel?, String>((ref, userId) async {
  final userRepository = ref.watch(userRepositoryProvider);
  try {
    return await userRepository.getUserById(userId);
  } catch (e) {
    debugPrint('Error fetching user profile: $e');
    return null;
  }
});

// Controller for user profile management
class UserController extends StateNotifier<AsyncValue<UserModel?>> {
  final UserRepository _userRepository;
  final Ref _ref;

  UserController(this._userRepository, this._ref) : super(const AsyncValue.loading()) {
    // Initialize by checking for current user
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    state = const AsyncValue.loading();
    try {
      final authState = _ref.read(authControllerProvider);
      final user = authState.value;
      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Upload and update user's profile image
  Future<void> updateProfileImage(BuildContext context, ImageSource source) async {
    final authState = _ref.read(authControllerProvider);
    final user = authState.value;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to update your profile')),
      );
      return;
    }

    try {
      // Pick image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (image == null) return;

      state = const AsyncValue.loading();

      // Convert to file
      final File imageFile = File(image.path);

      // Upload image
      final updatedUser = await _userRepository.uploadProfileImage(user, imageFile);

      // Update state
      state = AsyncValue.data(updatedUser);

      // Invalidate related providers
      _ref.invalidate(authControllerProvider);
      _ref.invalidate(userProfileProvider(user.id));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated successfully')),
      );
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile image: $e')),
      );
    }
  }

  // Upload and update user's cover photo
  Future<void> updateCoverPhoto(BuildContext context, ImageSource source) async {
    final authState = _ref.read(authControllerProvider);
    final user = authState.value;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to update your profile')),
      );
      return;
    }

    try {
      // Pick image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      state = const AsyncValue.loading();

      // Convert to file
      final File imageFile = File(image.path);

      // Upload image
      final updatedUser = await _userRepository.uploadCoverPhoto(user, imageFile);

      // Update state
      state = AsyncValue.data(updatedUser);

      // Invalidate related providers
      _ref.invalidate(authControllerProvider);
      _ref.invalidate(userProfileProvider(user.id));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cover photo updated successfully')),
      );
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating cover photo: $e')),
      );
    }
  }

  // Add multiple photos to user gallery
  Future<void> addPhotos(BuildContext context) async {
    final authState = _ref.read(authControllerProvider);
    final user = authState.value;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to update your profile')),
      );
      return;
    }

    try {
      // Pick multiple images
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (images.isEmpty) return;

      state = const AsyncValue.loading();

      // Convert to files
      final List<File> imageFiles = images.map((image) => File(image.path)).toList();

      // Upload images
      final updatedUser = await _userRepository.uploadUserImages(user, imageFiles);

      // Update state
      state = AsyncValue.data(updatedUser);

      // Invalidate related providers
      _ref.invalidate(authControllerProvider);
      _ref.invalidate(userProfileProvider(user.id));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${images.length} photos added successfully')),
      );
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding photos: $e')),
      );
    }
  }

  // Update user bio
  Future<void> updateBio(BuildContext context, String bio) async {
    final authState = _ref.read(authControllerProvider);
    final user = authState.value;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to update your profile')),
      );
      return;
    }

    try {
      state = const AsyncValue.loading();

      // Update user
      final updatedUser = await _userRepository.updateUserBio(user, bio);

      // Update state
      state = AsyncValue.data(updatedUser);

      // Invalidate related providers
      _ref.invalidate(authControllerProvider);
      _ref.invalidate(userProfileProvider(user.id));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bio updated successfully')),
      );
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating bio: $e')),
      );
    }
  }
}

// Provider for user controller
final userControllerProvider = StateNotifierProvider<UserController, AsyncValue<UserModel?>>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return UserController(userRepository, ref);
});