import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/data/models/event_model.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../controllers/event_controller.dart';

class EventHistoryScreen extends ConsumerStatefulWidget {
  const EventHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends ConsumerState<EventHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final eventsAsync = ref.watch(eventControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        title: const Text(
          'Event History',
          style: TextStyle(
            color: AppColors.primaryWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text(
                'Please log in to view your event history',
                style: TextStyle(color: AppColors.primaryWhite),
              ),
            );
          }

          return eventsAsync.when(
            data: (events) {
              final now = DateTime.now();

              // Get all past events this user participated in
              final pastEvents = events.where((event) =>
              (event.hostId == user.id || event.guestsId.contains(user.id)) &&
                  event.eventDateTime.isBefore(now)
              ).toList();

              if (pastEvents.isEmpty) {
                return _buildEmptyState();
              }

              // Sort by most recent first
              pastEvents.sort((a, b) => b.eventDateTime.compareTo(a.eventDateTime));

              // Group events by month
              final groupedEvents = _groupEventsByMonth(pastEvents);

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: groupedEvents.length,
                itemBuilder: (context, index) {
                  final monthYear = groupedEvents.keys.elementAt(index);
                  final monthEvents = groupedEvents[monthYear]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month header
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          monthYear,
                          style: const TextStyle(
                            color: AppColors.primaryPink,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Events for this month
                      ...monthEvents.map((event) =>
                          _buildEventHistoryItem(context, event, user.id)),
                    ],
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
      ),
    );
  }

  Map<String, List<EventModel>> _groupEventsByMonth(List<EventModel> events) {
    final Map<String, List<EventModel>> grouped = {};

    for (final event in events) {
      final monthYear = DateFormat('MMMM yyyy').format(event.eventDateTime);

      if (!grouped.containsKey(monthYear)) {
        grouped[monthYear] = [];
      }

      grouped[monthYear]!.add(event);
    }

    return grouped;
  }

  Widget _buildEventHistoryItem(BuildContext context, EventModel event, String userId) {
    final isHost = event.hostId == userId;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/chosen-event-details',
          arguments: event.eventId,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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

                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.secondaryWhite,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('E, MMM d, yyyy').format(event.eventDateTime),
                        style: const TextStyle(
                          color: AppColors.secondaryWhite,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.secondaryWhite,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.nameOfVenue,
                          style: const TextStyle(
                            color: AppColors.secondaryWhite,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Event status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isHost ? AppColors.primaryPink : Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isHost ? 'Hosted' : 'Attended',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
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
            Icons.history,
            color: AppColors.secondaryWhite,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No past events',
            style: TextStyle(
              color: AppColors.primaryWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your event history will appear here',
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
}