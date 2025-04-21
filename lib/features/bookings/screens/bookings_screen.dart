import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wyld/features/bookings/screens/widgets/widgets.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/data/models/event_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../bookings/controllers/event_controller.dart';
import '../../bookings/controllers/join_request_controller.dart';
import 'requests_screen.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final pendingRequestsAsync = ref.watch(hostPendingRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        title: const Text(
          'My Bookings',
          style: TextStyle(
            color: AppColors.primaryWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Notification badge for pending requests
          pendingRequestsAsync.when(
            data: (requests) {
              if (requests.isNotEmpty) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RequestsScreen()),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.notifications_none_outlined,
                          color: AppColors.primaryWhite,
                          size: 28,
                        ),
                        Positioned(
                          top: 5,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryPink,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${requests.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryPink,
          labelColor: AppColors.primaryPink,
          unselectedLabelColor: AppColors.secondaryWhite,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Hosting'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Pending Requests Notification Banner
          pendingRequestsAsync.when(
            data: (requests) {
              if (requests.isNotEmpty) {
                return PendingRequestsWidget(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RequestsScreen()),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Upcoming Events Tab
                _buildEventsList(context, 'upcoming'),

                // Hosting Tab
                _buildEventsList(context, 'hosting'),

                // Past Events Tab
                _buildEventsList(context, 'past'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(BuildContext context, String type) {
    final authState = ref.watch(authControllerProvider);
    final eventsAsync = ref.watch(eventControllerProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const Center(
            child: Text(
              'Please log in to view your bookings',
              style: TextStyle(color: AppColors.primaryWhite),
            ),
          );
        }

        return eventsAsync.when(
          data: (events) {
            final now = DateTime.now();
            List<EventModel> filteredEvents = [];

            if (type == 'upcoming') {
              // Events where user is a guest and date is in the future
              filteredEvents = events.where((event) =>
              event.guestsId.contains(user.id) &&
                  event.eventDateTime.isAfter(now)
              ).toList();
            } else if (type == 'hosting') {
              // Events where user is the host
              filteredEvents = events.where((event) =>
              event.hostId == user.id
              ).toList();
            } else if (type == 'past') {
              // Events user joined that are in the past
              filteredEvents = events.where((event) =>
              (event.guestsId.contains(user.id) || event.hostId == user.id) &&
                  event.eventDateTime.isBefore(now)
              ).toList();
            }

            if (filteredEvents.isEmpty) {
              return _buildEmptyState(type);
            }

            // Sort by date
            filteredEvents.sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));

            // For past events, show most recent first
            if (type == 'past') {
              filteredEvents = filteredEvents.reversed.toList();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredEvents.length,
              itemBuilder: (context, index) {
                final event = filteredEvents[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: BookingEventCard(
                    event: event,
                    isHost: event.hostId == user.id,
                    isPast: event.eventDateTime.isBefore(now),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/chosen-event-details',
                        arguments: event.eventId,
                      );
                    },
                  ),
                );
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
    );
  }

  Widget _buildEmptyState(String type) {
    String message = '';
    IconData icon = Icons.calendar_today_outlined;

    switch (type) {
      case 'upcoming':
        message = 'No upcoming bookings';
        icon = Icons.event_available;
        break;
      case 'hosting':
        message = 'You\'re not hosting any events';
        icon = Icons.home_outlined;
        break;
      case 'past':
        message = 'No past bookings';
        icon = Icons.history;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: AppColors.secondaryWhite,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.secondaryWhite,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 24),
          if (type == 'hosting' || type == 'upcoming')
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/create-event');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Create an Event'),
            ),
        ],
      ),
    );
  }
}