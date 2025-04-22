// Update to lib/features/chat/screens/main_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/data/models/event_model.dart';
import '../../../shared/widgets/profile_avatar_widget.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../bookings/controllers/event_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/direct_chat_controller.dart';
import '../data/models/direct_message_model.dart';

class MainChatScreen extends ConsumerStatefulWidget {
  const MainChatScreen({super.key});

  @override
  ConsumerState<MainChatScreen> createState() => _MainChatScreenState();
}

class _MainChatScreenState extends ConsumerState<MainChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize direct chats controller with current user ID
    Future.delayed(Duration.zero, () {
      final authState = ref.read(authControllerProvider);
      if (authState.hasValue && authState.value != null) {
        ref
            .read(userDirectChatsProvider.notifier)
            .initialize(authState.value!.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: AppColors.primaryWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryPink,
          labelColor: AppColors.primaryPink,
          unselectedLabelColor: AppColors.secondaryWhite,
          tabs: const [Tab(text: 'Event Chats'), Tab(text: 'Direct Messages')],
        ),
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text(
                'Please log in to view your messages',
                style: TextStyle(color: AppColors.primaryWhite),
              ),
            );
          }

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.primaryWhite),
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    hintStyle: const TextStyle(color: AppColors.secondaryWhite),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.secondaryWhite,
                    ),
                    filled: true,
                    fillColor: AppColors.secondaryBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Event Chats Tab
                    _buildEventChatsTab(user.id),
                    // Direct Messages Tab
                    // _buildDirectMessagesTab(user.id),
                    Column(
                      children: [
                        Text(
                          'Coming Soon!',
                          style: GoogleFonts.montserrat(
                            color: AppColors.primaryWhite,
                            fontSize: 36.0,
                          ),
                        ),
                        Image.asset('assets/gif/coming-soon.gif'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (_, __) => const Center(
              child: Text(
                'Error loading user data',
                style: TextStyle(color: Colors.red),
              ),
            ),
      ),
    );
  }

  Widget _buildDirectMessagesTab(String userId) {
    final directChatsAsync = ref.watch(userDirectChatsProvider);

    return directChatsAsync.when(
      data: (chats) {
        if (chats.isEmpty) {
          return _buildEmptyState(
            'No direct messages',
            'Start a conversation with a friend',
            Icons.chat_bubble_outline,
            () {
              // Navigate to friends list to start a new chat
              // Navigator.pushNamed(context, '/friend-requests');
            },
          );
        }

        // Filter chats based on search query if needed
        final filteredChats =
            _searchController.text.isEmpty
                ? chats
                : chats.where((chat) {
                  // Get the other participant's data and check if name contains search query
                  final otherUserId = chat.participants.firstWhere(
                    (id) => id != userId,
                    orElse: () => '',
                  );
                  final userAsync = ref.read(userByIdProvider(otherUserId));
                  if (userAsync.hasValue && userAsync.value != null) {
                    return userAsync.value!.name.toLowerCase().contains(
                      _searchController.text.toLowerCase(),
                    );
                  }
                  return false;
                }).toList();

        if (filteredChats.isEmpty) {
          return Center(
            child: Text(
              'No matches found for "${_searchController.text}"',
              style: const TextStyle(color: AppColors.secondaryWhite),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredChats.length,
          itemBuilder: (context, index) {
            final chat = filteredChats[index];
            return _buildDirectChatItem(chat, userId);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, _) => Center(
            child: Text(
              'Error loading direct messages: $error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
    );
  }

  Widget _buildDirectChatItem(DirectMessageChat chat, String currentUserId) {
    // Find the other participant's ID
    final otherUserId = chat.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) return const SizedBox.shrink();

    final userAsync = ref.watch(userByIdProvider(otherUserId));

    return userAsync.when(
      data: (otherUser) {
        if (otherUser == null) return const SizedBox.shrink();

        final isUnread = chat.hasUnread && chat.lastSenderId != currentUserId;
        final formattedTime = _formatChatTime(chat.lastMessageTime);

        return InkWell(
          onTap: () {
            // Navigate to direct chat screen
            Navigator.pushNamed(
              context,
              '/direct-chat',
              arguments: {'chatId': chat.chatId, 'otherUserId': otherUserId},
            );

            // Mark as read if needed
            if (isUnread) {
              ref
                  .read(userDirectChatsProvider.notifier)
                  .markChatAsRead(chat.chatId);
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  isUnread
                      ? AppColors.secondaryBackground.withOpacity(0.7)
                      : AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(12),
              border:
                  isUnread
                      ? Border.all(color: AppColors.primaryPink, width: 1)
                      : null,
            ),
            child: Row(
              children: [
                // User avatar
                ProfileAvatar(
                  userId: otherUserId,
                  radius: 30,
                  showOnlineIndicator: true,
                ),

                const SizedBox(width: 16),

                // Message preview
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            otherUser.name,
                            style: TextStyle(
                              color: AppColors.primaryWhite,
                              fontWeight:
                                  isUnread
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            formattedTime,
                            style: TextStyle(
                              color:
                                  isUnread
                                      ? AppColors.primaryPink
                                      : AppColors.secondaryWhite,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.lastSenderId == currentUserId
                                  ? 'You: ${chat.lastMessage}'
                                  : chat.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color:
                                    isUnread
                                        ? AppColors.primaryWhite
                                        : AppColors.secondaryWhite,
                                fontWeight:
                                    isUnread
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryPink,
                                shape: BoxShape.circle,
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
        );
      },
      loading:
          () => const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildEventChatsTab(String userId) {
    final eventsAsync = ref.watch(eventControllerProvider);

    return eventsAsync.when(
      data: (events) {
        // Filter events where the user is a participant (either as host or guest)
        final participatingEvents =
            events
                .where(
                  (event) =>
                      event.hostId == userId || event.guestsId.contains(userId),
                )
                .toList();

        if (participatingEvents.isEmpty) {
          return _buildEmptyState(
            'No event chats',
            'Join or host an event to start chatting',
            Icons.event_available,
            () {
              // Navigate to explore tab
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            },
          );
        }

        // Filter events based on search query if needed
        final filteredEvents =
            _searchController.text.isEmpty
                ? participatingEvents
                : participatingEvents.where((event) {
                  return event.eventTitle.toLowerCase().contains(
                    _searchController.text.toLowerCase(),
                  );
                }).toList();

        if (filteredEvents.isEmpty) {
          return Center(
            child: Text(
              'No matches found for "${_searchController.text}"',
              style: const TextStyle(color: AppColors.secondaryWhite),
            ),
          );
        }

        // Sort by date (most recent first)
        filteredEvents.sort(
          (a, b) => b.eventDateTime.compareTo(a.eventDateTime),
        );

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredEvents.length,
          itemBuilder: (context, index) {
            final event = filteredEvents[index];
            return _buildEventChatItem(event, userId);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, _) => Center(
            child: Text(
              'Error loading events: $error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
    );
  }

  Widget _buildEventChatItem(EventModel event, String userId) {
    final unreadCountAsync = ref.watch(
      unreadMessageCountProvider({'userId': userId, 'eventId': event.eventId}),
    );
    final hostAsync = ref.watch(userByIdProvider(event.hostId));

    return InkWell(
      onTap: () {
        // Navigate to event chat screen
        Navigator.pushNamed(context, '/chat', arguments: event.eventId);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
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
                borderRadius: BorderRadius.circular(12),
                image:
                    event.venueImages.isNotEmpty
                        ? DecorationImage(
                          image: NetworkImage(event.venueImages[0]),
                          fit: BoxFit.cover,
                        )
                        : null,
                color: event.venueImages.isEmpty ? AppColors.grayBorder : null,
              ),
              child:
                  event.venueImages.isEmpty
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.secondaryWhite,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, h:mm a').format(event.eventDateTime),
                        style: const TextStyle(
                          color: AppColors.secondaryWhite,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Host info
                      Row(
                        children: [
                          const Text(
                            'Host: ',
                            style: TextStyle(
                              color: AppColors.secondaryWhite,
                              fontSize: 12,
                            ),
                          ),
                          hostAsync.when(
                            data:
                                (host) => Text(
                                  host?.name ?? 'Unknown',
                                  style: const TextStyle(
                                    color: AppColors.primaryWhite,
                                    fontSize: 12,
                                  ),
                                ),
                            loading:
                                () => const SizedBox(
                                  width: 50,
                                  height: 12,
                                  child: LinearProgressIndicator(),
                                ),
                            error:
                                (_, __) => const Text(
                                  'Unknown',
                                  style: TextStyle(
                                    color: AppColors.primaryWhite,
                                    fontSize: 12,
                                  ),
                                ),
                          ),
                        ],
                      ),

                      // Unread count
                      unreadCountAsync.when(
                        data: (count) {
                          if (count > 0) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryPink,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                count > 99 ? '99+' : count.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onActionPressed,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.secondaryWhite, size: 64),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primaryWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.secondaryWhite,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onActionPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }

  String _formatChatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 7) {
      return DateFormat('MM/dd/yy').format(time);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}
