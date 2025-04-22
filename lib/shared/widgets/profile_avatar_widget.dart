import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/models/user_model.dart';

class ProfileAvatar extends ConsumerWidget {
  final String userId;
  final double radius;
  final bool showOnlineIndicator;
  final bool showFriendIndicator;

  const ProfileAvatar({
    super.key,
    required this.userId,
    this.radius = 30,
    this.showOnlineIndicator = false,
    this.showFriendIndicator = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(userId));
    final currentUserAsync = ref.watch(authControllerProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return _buildDefaultAvatar();
        }

        // Check if the user is a friend of the current user
        final currentUser = currentUserAsync.value;
        final isFriend = currentUser != null &&
            currentUser.friendsList.contains(userId);

        return _buildProfileAvatar(user, isFriend);
      },
      loading: () => _buildLoadingAvatar(),
      error: (_, __) => _buildDefaultAvatar(),
    );
  }

  Widget _buildProfileAvatar(UserModel user, bool isFriend) {
    // Determine the image URL
    final imageUrl = user.profileImages.isNotEmpty
        ? user.profileImages[0]
        : (user.userImages.isNotEmpty ? user.userImages[0] : '');

    // Build the avatar container
    Widget avatarWidget = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: isFriend && showFriendIndicator
            ? Border.all(
          color: AppColors.primaryPink,
          width: 3.0,
        )
            : null,
        image: imageUrl.isNotEmpty
            ? DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        )
            : null,
        color: imageUrl.isEmpty ? AppColors.grayBorder : null,
      ),
      child: imageUrl.isEmpty
          ? Icon(
        Icons.person,
        color: AppColors.primaryWhite,
        size: radius,
      )
          : null,
    );

    // Add online indicator if required
    if (showOnlineIndicator) {
      avatarWidget = Stack(
        children: [
          avatarWidget,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: radius / 1.5,
              height: radius / 1.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
                border: Border.all(
                  color: AppColors.primaryBackground,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return avatarWidget;
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.grayBorder,
      ),
      child: Icon(
        Icons.person,
        color: AppColors.primaryWhite,
        size: radius,
      ),
    );
  }

  Widget _buildLoadingAvatar() {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.secondaryBackground,
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPink),
        ),
      ),
    );
  }
}