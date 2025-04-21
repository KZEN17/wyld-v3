import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../features/auth/controllers/auth_controller.dart';

class ProfileAvatar extends ConsumerWidget {
  final String userId;
  final double radius;
  final bool showOnlineIndicator;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    required this.userId,
    this.radius = 25,
    this.showOnlineIndicator = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(userId));

    return GestureDetector(
      onTap: onTap ?? () {
        // Default action is to navigate to user profile
        Navigator.of(context).pushNamed('/user-profile-view', arguments: userId);
      },
      child: Stack(
        children: [
          userAsync.when(
            data: (user) {
              if (user == null) {
                return _buildDefaultAvatar();
              }

              return CircleAvatar(
                radius: radius,
                backgroundColor: AppColors.secondaryBackground,
                backgroundImage: user.profileImages.isNotEmpty
                    ? NetworkImage(user.profileImages[0])
                    : (user.userImages.isNotEmpty
                    ? NetworkImage(user.userImages[0])
                    : null),
                child: user.profileImages.isEmpty && user.userImages.isEmpty
                    ? Icon(
                  Icons.person,
                  color: AppColors.primaryWhite,
                  size: radius * 0.8,
                )
                    : null,
              );
            },
            loading: () => _buildLoadingAvatar(),
            error: (_, __) => _buildErrorAvatar(),
          ),

          // Online indicator
          if (showOnlineIndicator)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: radius * 0.3,
                height: radius * 0.3,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryBackground,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.secondaryBackground,
      child: Icon(
        Icons.person,
        color: AppColors.primaryWhite,
        size: radius * 0.8,
      ),
    );
  }

  Widget _buildLoadingAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.secondaryBackground,
      child: SizedBox(
        width: radius * 0.8,
        height: radius * 0.8,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPink),
        ),
      ),
    );
  }

  Widget _buildErrorAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.secondaryBackground,
      child: Icon(
        Icons.error,
        color: Colors.red,
        size: radius * 0.8,
      ),
    );
  }
}