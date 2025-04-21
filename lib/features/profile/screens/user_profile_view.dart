import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';
import '../widgets/friend_request_button.dart';
import '../controllers/friend_controller.dart';
import '../controllers/user_controller.dart';

class UserProfileView extends ConsumerStatefulWidget {
  final String userId;

  const UserProfileView({super.key, required this.userId});

  @override
  ConsumerState<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends ConsumerState<UserProfileView> {
  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(authControllerProvider);
    final userAsync = ref.watch(userProfileProvider(widget.userId));
    final friendshipStatusAsync = ref.watch(friendshipStatusProvider(widget.userId));

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found', style: TextStyle(color: AppColors.primaryWhite)));
          }

          return currentUserAsync.when(
            data: (currentUser) {
              if (currentUser == null) {
                return const Center(child: Text('You need to be logged in to view profiles', style: TextStyle(color: AppColors.primaryWhite)));
              }

              // Check if this is the current user's own profile
              final bool isOwnProfile = currentUser.id == user.id;

              return friendshipStatusAsync.when(
                data: (status) {
                  return _buildProfileUI(context, user, currentUser, isOwnProfile, status);
                },
                loading: () => _buildProfileUI(context, user, currentUser, isOwnProfile, FriendshipStatus.none),
                error: (_, __) => _buildProfileUI(context, user, currentUser, isOwnProfile, FriendshipStatus.none),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Error loading current user', style: TextStyle(color: Colors.red))),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error loading user profile: $error', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildProfileUI(BuildContext context, UserModel user, UserModel currentUser, bool isOwnProfile, FriendshipStatus friendStatus) {
    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        shrinkWrap: true,
        children: [
          _buildCoverPhoto(context, user),
          _buildProfileHeader(user, currentUser, isOwnProfile, friendStatus),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40.0),
                _buildBioSection(user),
                const Divider(
                  color: AppColors.secondaryBackground,
                  thickness: 1.0,
                ),
                const SizedBox(height: 40.0),
                _buildPhotosSection(user),
                const Divider(
                  color: AppColors.secondaryBackground,
                  thickness: 1.0,
                ),
                const SizedBox(height: 40.0),
                _buildHostedSection(user),
                const Divider(
                  color: AppColors.secondaryBackground,
                  thickness: 1.0,
                ),
                const SizedBox(height: 40.0),
                _buildFriendsSection(user),
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverPhoto(BuildContext context, UserModel user) {
    return Container(
      color: AppColors.primaryPink,
      height: MediaQuery.of(context).size.height * 0.2,
      child: Stack(
        children: [
          // Cover photo
          user.coverPhoto.isNotEmpty
              ? Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.cover,
                image: NetworkImage(user.coverPhoto),
              ),
            ),
          )
              : Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryPink.withOpacity(0.8),
                  AppColors.primaryRed.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Back button
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user, UserModel currentUser, bool isOwnProfile, FriendshipStatus friendStatus) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile image
          CircleAvatar(
            radius: 50.0,
            backgroundColor: AppColors.secondaryBackground,
            backgroundImage: user.profileImages.isNotEmpty
                ? NetworkImage(user.profileImages[0])
                : (user.userImages.isNotEmpty ? NetworkImage(user.userImages[0]) : null),
            child: user.profileImages.isEmpty && user.userImages.isEmpty
                ? const Icon(Icons.person, color: AppColors.primaryWhite, size: 50)
                : null,
          ),

          const SizedBox(width: 20),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    color: AppColors.primaryWhite,
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.secondaryWhite, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      user.latitude != 0 && user.longitude != 0
                          ? 'Nashville, TN' // In a real app, you'd reverse geocode the coordinates
                          : 'Location not set',
                      style: const TextStyle(
                        color: AppColors.secondaryWhite,
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Only show friend button if not the current user's profile
                if (!isOwnProfile)
                  FriendRequestButton(
                    targetUserId: user.id,
                    friendshipStatus: friendStatus,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bio',
          style: TextStyle(
            color: AppColors.primaryWhite,
            fontSize: 20.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            user.bio.isNotEmpty ? user.bio : 'No bio added yet.',
            style: const TextStyle(
              fontSize: 16.0,
              color: AppColors.secondaryWhite,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosSection(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            'Photos',
            style: TextStyle(
              color: AppColors.primaryWhite,
              fontSize: 20.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        user.userImages.isNotEmpty
            ? GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: user.userImages.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10.0,
            crossAxisSpacing: 10.0,
          ),
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _showFullScreenImage(context, user.userImages[index]),
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: NetworkImage(user.userImages[index]),
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            );
          },
        )
            : const Padding(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            'No photos added yet.',
            style: TextStyle(
              color: AppColors.secondaryWhite,
              fontSize: 16.0,
            ),
          ),
        ),
      ],
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.error, color: Colors.red, size: 50),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHostedSection(UserModel user) {
    // This would show events hosted by this user
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            'Events Hosted',
            style: TextStyle(
              color: AppColors.primaryWhite,
              fontSize: 20.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            'No events hosted yet.',
            style: TextStyle(
              color: AppColors.secondaryWhite,
              fontSize: 16.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFriendsSection(UserModel user) {
    // This section would show the user's friends with their avatars
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Friends',
              style: TextStyle(
                color: AppColors.primaryWhite,
                fontSize: 20.0,
                fontWeight: FontWeight.w600,
              ),
            ),

            if (user.friendsList.isNotEmpty)
              TextButton(
                onPressed: () {
                  // Navigate to full friends list
                },
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: AppColors.primaryPink,
                    fontSize: 14.0,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 10),

        user.friendsList.isEmpty
            ? const Padding(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            'No friends yet.',
            style: TextStyle(
              color: AppColors.secondaryWhite,
              fontSize: 16.0,
            ),
          ),
        )
            : SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: user.friendsList.length > 10 ? 10 : user.friendsList.length,
            itemBuilder: (context, index) {
              return _buildFriendItem(user.friendsList[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFriendItem(String friendId) {
    final friendAsync = ref.watch(userByIdProvider(friendId));

    return GestureDetector(
      onTap: () {
        // Navigate to friend's profile
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => UserProfileView(userId: friendId),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: Column(
          children: [
            friendAsync.when(
              data: (friend) {
                return Stack(
                  children: [
                    // Friend avatar
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.secondaryBackground,
                      backgroundImage: friend?.profileImages.isNotEmpty == true
                          ? NetworkImage(friend!.profileImages[0])
                          : (friend?.userImages.isNotEmpty == true ? NetworkImage(friend!.userImages[0]) : null),
                      child: friend?.profileImages.isEmpty == true && friend?.userImages.isEmpty == true
                          ? const Icon(Icons.person, color: AppColors.primaryWhite)
                          : null,
                    ),

                    // Online indicator (could be implemented with a real-time status)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
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
                );
              },
              loading: () => const CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.secondaryBackground,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => const CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.secondaryBackground,
                child: Icon(Icons.error, color: Colors.red),
              ),
            ),

            const SizedBox(height: 4),

            friendAsync.when(
              data: (friend) => Container(
                width: 65,
                alignment: Alignment.center,
                child: Text(
                  friend?.name ?? 'Unknown',
                  style: const TextStyle(
                    color: AppColors.secondaryWhite,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              loading: () => Container(
                width: 65,
                height: 12,
                color: Colors.transparent,
              ),
              error: (_, __) => Container(
                width: 65,
                alignment: Alignment.center,
                child: const Text(
                  'Error',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
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