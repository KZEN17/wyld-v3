import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/friend_controller.dart';
import '../models/friend_request_model.dart';
import '../../auth/controllers/auth_controller.dart';

class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingRequestsAsync = ref.watch(pendingFriendRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        title: const Text(
          'Friend Requests',
          style: TextStyle(color: AppColors.primaryWhite),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: pendingRequestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return const Center(
              child: Text(
                'No pending friend requests',
                style: TextStyle(color: AppColors.secondaryWhite, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildRequestItem(context, ref, request);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Error loading requests: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestItem(BuildContext context, WidgetRef ref, FriendRequest request) {
    final senderAsync = ref.watch(userByIdProvider(request.senderId));

    return senderAsync.when(
      data: (sender) {
        if (sender == null) {
          return const SizedBox(); // Skip if user not found
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Card(
            color: AppColors.secondaryBackground,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // User avatar
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.grayBorder,
                    backgroundImage: sender.profileImages.isNotEmpty
                        ? NetworkImage(sender.profileImages[0])
                        : (sender.userImages.isNotEmpty
                        ? NetworkImage(sender.userImages[0])
                        : null),
                    child: sender.profileImages.isEmpty && sender.userImages.isEmpty
                        ? const Icon(Icons.person, color: AppColors.primaryWhite)
                        : null,
                  ),

                  const SizedBox(width: 16),

                  // User info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sender.name,
                          style: const TextStyle(
                            color: AppColors.primaryWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Sent you a friend request',
                          style: TextStyle(
                            color: AppColors.secondaryWhite,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _acceptRequest(context, ref, request.senderId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryPink,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Accept'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _declineRequest(context, ref, request.senderId),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.secondaryWhite,
                                ),
                                child: const Text('Decline'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox(),
    );
  }

  Future<void> _acceptRequest(BuildContext context, WidgetRef ref, String senderId) async {
    try {
      await ref.read(friendControllerProvider).acceptFriendRequest(senderId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request accepted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting request: $e')),
      );
    }
  }

  Future<void> _declineRequest(BuildContext context, WidgetRef ref, String senderId) async {
    try {
      await ref.read(friendControllerProvider).declineFriendRequest(senderId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request declined')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error declining request: $e')),
      );
    }
  }
}