import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/models/user_model.dart';

// Provider for user repository
final userRepositoryProvider = Provider((ref) {
  return UserRepository(
    db: Databases(
      Client()
        ..setEndpoint(AppwriteConstants.endpoint)
        ..setProject(AppwriteConstants.projectId)
        ..setSelfSigned(status: true),
    ),
    storage: Storage(
      Client()
        ..setEndpoint(AppwriteConstants.endpoint)
        ..setProject(AppwriteConstants.projectId)
        ..setSelfSigned(status: true),
    ),
  );
});

class UserRepository {
  final Databases _db;
  final Storage _storage;

  UserRepository({required Databases db, required Storage storage})
      : _db = db,
        _storage = storage;

  // Get user by ID
  Future<UserModel> getUserById(String userId) async {
    try {
      final response = await _db.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId,
      );

      return UserModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile (general-purpose method)
  Future<UserModel> updateUserProfile(UserModel userModel) async {
    try {
      final response = await _db.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userModel.id,
        data: userModel.toJson(),
      );

      return UserModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // Upload and set as profile image
  Future<UserModel> uploadProfileImage(UserModel user, File imageFile) async {
    try {
      // Upload the image to storage
      final uploadedFile = await _storage.createFile(
        bucketId: AppwriteConstants.imagesBucket,
        fileId: ID.unique(),
        file: InputFile.fromPath(
          path: imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      );

      // Generate image URL
      final imageUrl = '${AppwriteConstants.endpoint}/storage/buckets/${AppwriteConstants.imagesBucket}/files/${uploadedFile.$id}/preview?project=${AppwriteConstants.projectId}';

      // Create a copy of the user with updated profile image
      final updatedUser = user.copyWith(
        profileImages: [imageUrl, ...user.profileImages],
        // Also add to userImages if not already there
        userImages: user.userImages.contains(imageUrl)
            ? user.userImages
            : [imageUrl, ...user.userImages],
      );

      // Update the user in the database
      return await updateUserProfile(updatedUser);
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading profile image: $e');
      }
      rethrow;
    }
  }

  // Upload and set as cover photo
  Future<UserModel> uploadCoverPhoto(UserModel user, File imageFile) async {
    try {
      // Upload the image to storage
      final uploadedFile = await _storage.createFile(
        bucketId: AppwriteConstants.imagesBucket,
        fileId: ID.unique(),
        file: InputFile.fromPath(
          path: imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      );

      // Generate image URL
      final imageUrl = '${AppwriteConstants.endpoint}/storage/buckets/${AppwriteConstants.imagesBucket}/files/${uploadedFile.$id}/preview?project=${AppwriteConstants.projectId}';

      // Create a copy of the user with updated cover photo
      final updatedUser = user.copyWith(
        coverPhoto: imageUrl,
        // Also add to userImages if not already there
        userImages: user.userImages.contains(imageUrl)
            ? user.userImages
            : [imageUrl, ...user.userImages],
      );

      // Update the user in the database
      return await updateUserProfile(updatedUser);
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading cover photo: $e');
      }
      rethrow;
    }
  }

  // Upload multiple images to user gallery
  Future<UserModel> uploadUserImages(UserModel user, List<File> imageFiles) async {
    try {
      final List<String> imageUrls = [];

      // Upload each image to storage
      for (final imageFile in imageFiles) {
        final uploadedFile = await _storage.createFile(
          bucketId: AppwriteConstants.imagesBucket,
          fileId: ID.unique(),
          file: InputFile.fromPath(
            path: imageFile.path,
            filename: imageFile.path.split('/').last,
          ),
        );

        // Generate image URL and add to list
        final imageUrl = '${AppwriteConstants.endpoint}/storage/buckets/${AppwriteConstants.imagesBucket}/files/${uploadedFile.$id}/preview?project=${AppwriteConstants.projectId}';
        imageUrls.add(imageUrl);
      }

      // Create a copy of the user with updated images
      final updatedUser = user.copyWith(
        userImages: [...imageUrls, ...user.userImages],
      );

      // Update the user in the database
      return await updateUserProfile(updatedUser);
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading user images: $e');
      }
      rethrow;
    }
  }

  // Update user bio
  Future<UserModel> updateUserBio(UserModel user, String bio) async {
    try {
      // Create a copy of the user with updated bio
      final updatedUser = user.copyWith(bio: bio);

      // Update the user in the database
      return await updateUserProfile(updatedUser);
    } catch (e) {
      rethrow;
    }
  }
}