import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/data/models/event_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../bookings/controllers/event_controller.dart';
import '../controllers/chat_controller.dart';

class MainChatScreen extends ConsumerStatefulWidget {
  const MainChatScreen({super.key});

  @override
  ConsumerState<MainChatScreen> createState() => _MainChatScreenState();
}

class _MainChatScreenState extends ConsumerState<MainChatScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final eventsAsync = ref.watch(eventControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        title: const Text(
          'Chat',
          style: TextStyle(
            color: AppColors.primaryWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text(
                'Please log in to view your chats',
                style: TextStyle(color: AppColors.primaryWhite),
              ),
            );
          }

          return eventsAsync.when(
            data: (events) {
              // Filter events the user is part of (either as host or guest)
              final userEvents = events.where((event) =>
              event.hostId == user.id || event.guestsId.contains(user.id)
              ).toList();

              if (userEvents.isEmpty) {
                return _buildEmptyState();
              }

              // Sort by most recent first
              userEvents.sort((a, b) => b.eventDateTime.compareTo(a.eventDateTime));

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: userEvents.length,
                itemBuilder: (context, index) {
                  final event = userEvents[index];
                  return _buildChatItem(event, user.id);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text(
                'Error loading events: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text(
            'Error loading user data',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            color: AppColors.secondaryWhite,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No chats available',
            style: TextStyle(
              color: AppColors.primaryWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Join or host an event to start chatting',
            style: TextStyle(
              color: AppColors.secondaryWhite,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/explore');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('Explore Events'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(EventModel event, String userId) {
    // Check for unread messages count
    final unreadCountAsync = ref.watch(
        unreadMessageCountProvider({'userId': userId, 'eventId': event.eventId})
    );

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: event.eventId,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Event image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: event.venueImages.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(event.venueImages[0]),
                  fit: BoxFit.cover,
                )
                    : null,
                color: AppColors.grayBorder,
              ),
              child: event.venueImages.isEmpty
                  ? const Icon(Icons.event, color: AppColors.primaryWhite)
                  : null,
            ),

            const SizedBox(width: 16),

            // Event details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.eventTitle,
                    style: const TextStyle(
                      color: AppColors.primaryWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  Text(
                    DateFormat('E, MMM d • h:mm a').format(event.eventDateTime),
                    style: const TextStyle(
                      color: AppColors.secondaryWhite,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(
                        Icons.people_outline,
                        color: AppColors.secondaryWhite,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.guestsId.length} participants',
                        style: const TextStyle(
                          color: AppColors.secondaryWhite,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Unread count badge
            unreadCountAsync.when(
              data: (count) {
                if (count > 0) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryPink,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}