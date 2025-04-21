import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/appwrite_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final AppwriteService _appwriteService;

  AuthRepository(this._appwriteService);

  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    String phone = '',
  }) async {
    final user = await _appwriteService.createAccount(
      email: email,
      password: password,
      name: name,
    );

    // If phone is provided, update the user profile
    if (phone.isNotEmpty) {
      final updatedUser = user.copyWith(phone: phone);
      return await _appwriteService.updateUserProfile(updatedUser);
    }

    return user;
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    return await _appwriteService.login(email: email, password: password);
  }

  Future<void> logout() async {
    await _appwriteService.logout();
  }
  Future<UserModel> getUserById(String userId) async {
    return await _appwriteService.getUserById(userId);
  }

  Future<UserModel?> getCurrentUser() async {
    return await _appwriteService.getCurrentUser();
  }

  Future<UserModel> updateUserProfile(UserModel userModel) async {
    return await _appwriteService.updateUserProfile(userModel);
  }

  Future<UserModel> uploadProfileImages({
    required UserModel userModel,
    required List<File> imageFiles,
  }) async {
    return await _appwriteService.updateUserProfileWithImages(
      userModel,
      imageFiles,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final appwriteService = ref.watch(appwriteServiceProvider);
  return AuthRepository(appwriteService);
});
