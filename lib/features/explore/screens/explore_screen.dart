import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wyld/features/explore/screens/chosen_event_details.dart';
import '../../../core/constants/app_colors.dart';
import '../../bookings/controllers/event_controller.dart';
import '../widgets/event_card.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh events data when the screen loads
    Future.delayed(Duration.zero, () {
      ref.read(eventControllerProvider.notifier).getEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: RefreshIndicator(
        onRefresh: () async {
          // Pull to refresh functionality
          await ref.read(eventControllerProvider.notifier).getEvents();
        },
        color: AppColors.primaryPink,
        backgroundColor: AppColors.secondaryBackground,
        child: eventsAsync.when(
          data: (events) {
            if (events.isEmpty) {
              return const Center(
                child: Text(
                  'No events available',
                  style: TextStyle(color: AppColors.primaryWhite, fontSize: 16),
                ),
              );
            }

            // Sort events by date (most recent first)
            final sortedEvents = [...events];
            sortedEvents.sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8.0, bottom: 16.0),
                  child: Text(
                    'Upcoming Tables',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryWhite,
                    ),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedEvents.length,
                  itemBuilder: (context, index) {
                    final event = sortedEvents[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: EventCard(
                        event: event,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ChosenEventDetails(
                                eventId: event.eventId,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPink),
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.primaryRed,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading events: $error',
                    style: const TextStyle(
                      color: AppColors.primaryWhite,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(eventControllerProvider.notifier).getEvents();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPink,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}