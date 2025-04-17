import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/models/user_model.dart';
import '../constants/app_constants.dart';

class AppwriteService {
  final Client _client = Client();
  late Account _account;
  late Databases _databases;
  late Storage _storage;

  AppwriteService() {
    _client
        .setEndpoint(AppwriteConstants.endpoint)
        .setProject(AppwriteConstants.projectId)
        .setSelfSigned(status: true);

    _account = Account(_client);
    _databases = Databases(_client);
    _storage = Storage(_client);
  }

  Future<UserModel> createAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final models.User appwriteUser = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );

      // Create email session
      await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      final userModel = UserModel(
        id: appwriteUser.$id,
        email: email,
        name: name,
        gender: '',
        phone: '',
        userImages: [],
        profileImages: [],
        bio: '',
        coverPhoto: '',
        profileComplete: false,
        latitude: 0,
        longitude: 0,
        eventsHosted: [],
        eventsAttended: [],
        friendsList: [],
        lookingFor: '',
      );

      // Use arrays directly as expected by Appwrite
      await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: appwriteUser.$id,
        data: userModel.toJson(),
      );

      return userModel;
    } on AppwriteException catch (e) {
      if (kDebugMode) {
        print('Error creating account: ${e.message}');
      }
      rethrow;
    }
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      final models.User appwriteUser = await _account.get();

      final response = await _databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: appwriteUser.$id,
      );

      return UserModel.fromJson(response.data);
    } on AppwriteException catch (e) {
      if (kDebugMode) {
        print('Error logging in: ${e.message}');
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } on AppwriteException catch (e) {
      if (kDebugMode) {
        print('Error logging out: ${e.message}');
      }
      rethrow;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final models.User appwriteUser = await _account.get();

      final response = await _databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: appwriteUser.$id,
      );

      return UserModel.fromJson(response.data);
    } on AppwriteException catch (e) {
      if (kDebugMode) {
        print('Error getting current user: ${e.message}');
      }
      return null;
    }
  }

  Future<UserModel> updateUserProfile(UserModel userModel) async {
    try {
      final response = await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userModel.id,
        data: userModel.toJson(),
      );

      return UserModel.fromJson(response.data);
    } on AppwriteException catch (e) {
      if (kDebugMode) {
        print('Error updating user profile: ${e.message}');
      }
      rethrow;
    }
  }

  Future<List<String>> uploadProfileImages(
    List<File> imageFiles,
    String userId,
  ) async {
    final List<String> imageUrls = [];

    for (var imageFile in imageFiles) {
      try {
        final uploadedFile = await _storage.createFile(
          bucketId: AppwriteConstants.imagesBucket,
          fileId: ID.unique(),
          file: InputFile.fromPath(
            path: imageFile.path,
            filename: imageFile.path.split('/').last,
          ),
        );

        // CORRECT WAY: Build the URL string directly instead of using toString()
        final String fileUrl =
            '${AppwriteConstants.endpoint}/storage/buckets/${AppwriteConstants.imagesBucket}/files/${uploadedFile.$id}/preview?project=${AppwriteConstants.projectId}';

        imageUrls.add(fileUrl);
      } catch (e) {
        if (kDebugMode) {
          print('Error uploading image: $e');
        }
      }
    }

    return imageUrls;
  }

  Future<UserModel> updateUserProfileWithImages(
    UserModel userModel,
    List<File> imageFiles,
  ) async {
    try {
      // Upload images and get URLs
      final List<String> imageUrls = await uploadProfileImages(
        imageFiles,
        userModel.id,
      );

      if (imageUrls.isEmpty) {
        if (kDebugMode) {
          print('No images were successfully uploaded');
        }
        return userModel;
      }

      // Add all images to userImages array
      final List<String> updatedUserImages = [
        ...userModel.userImages,
        ...imageUrls,
      ];

      // Decide which images go to profile images
      List<String> updatedProfileImages = [...userModel.profileImages];
      if (userModel.profileImages.isEmpty && imageUrls.isNotEmpty) {
        updatedProfileImages.add(imageUrls[0]);
      }

      // Create updated model
      final updatedUser = userModel.copyWith(
        userImages: updatedUserImages,
        profileImages: updatedProfileImages,
      );

      // Use the full user model data for the update
      final response = await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userModel.id,
        data: updatedUser.toJson(),
      );

      if (kDebugMode) {
        print('Profile update successful');
      }

      return UserModel.fromJson(response.data);
    } catch (e) {
      if (kDebugMode) {
        print('Error in updateUserProfileWithImages: $e');
        if (e is AppwriteException) {
          print('Appwrite error code: ${e.code}');
          print('Appwrite error message: ${e.message}');
        }
      }
      rethrow;
    }
  }
}

final appwriteServiceProvider = Provider<AppwriteService>((ref) {
  return AppwriteService();
});
