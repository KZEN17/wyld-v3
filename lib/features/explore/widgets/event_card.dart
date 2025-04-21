import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/data/models/event_model.dart';
import '../../auth/controllers/auth_controller.dart';

class EventCard extends ConsumerWidget {
  final EventModel event;
  final VoidCallback onTap;

  const EventCard({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final bool isUpcoming = event.eventDateTime.isAfter(now);
    final totalGuests =
        (event.numberOfGuests['men'] ?? 0) +
            (event.numberOfGuests['women'] ?? 0);
    final availableSpace = totalGuests - event.guestsId.length;
    final hostAsync = ref.watch(userByIdProvider(event.hostId));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 320.0,
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Image Section
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: SizedBox(
                height: 160,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Event image or placeholder
                    event.venueImages.isNotEmpty
                        ? Image.network(
                      event.venueImages[0],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.grayBorder,
                          child: const Icon(
                            Icons.broken_image,
                            color: AppColors.secondaryWhite,
                            size: 40,
                          ),
                        );
                      },
                    )
                        : Container(
                      color: AppColors.grayBorder,
                      child: const Icon(
                        Icons.image,
                        color: AppColors.secondaryWhite,
                        size: 40,
                      ),
                    ),

                    // Guest count badge
                    Positioned(
                      top: 0,
                      left: 20,
                      child: Container(
                        height: 50,
                        width: 48,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(15),
                            bottomLeft: Radius.circular(15),
                          ),
                          color: AppColors.primaryWhite,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$totalGuests',
                              style: const TextStyle(
                                color: AppColors.primaryPink,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(
                              'Guests',
                              style: TextStyle(
                                color: AppColors.primaryBackground,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Event Title
                    Text(
                      event.eventTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryWhite,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Venue
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.secondaryWhite,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.nameOfVenue,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.secondaryWhite,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Date and time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              color: AppColors.secondaryWhite,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat(
                                'd MMM, h:mm a',
                              ).format(event.eventDateTime),
                              style: const TextStyle(
                                color: AppColors.secondaryWhite,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        // Host column
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: const Text(
                            'Host',
                            style: TextStyle(
                              color: AppColors.secondaryWhite,
                              fontSize: 10.0,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(
                      height: 40, // Fixed height to prevent overflow
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center, // Changed to center
                        children: [
                          // For consistency with your example
                          if (isUpcoming && availableSpace > 0)
                            Text(
                              '$availableSpace Spaces Left',
                              style: const TextStyle(
                                color: Color(0xFFFFD600),
                                fontSize: 16.0,
                                fontWeight: FontWeight.w400,
                              ),
                            )
                          else
                            const SizedBox.shrink(),

                          // Guests and Host
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,

                            children: [
                              if (event.guestsId.isNotEmpty)
                                SizedBox(
                                  height: 32,
                                  width: event.guestsId.length < 3 ? event.guestsId.length * 35 : 100,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: event.guestsId.length > 3 ? 3 : event.guestsId.length,
                                    itemBuilder: (context, index) {
                                      return _buildGuestItem(context, ref, event.guestsId[index]);
                                    },
                                  ),
                                ),

                              // Vertical divider
                              if (event.guestsId.isNotEmpty)
                                Container(
                                  height: 32.0,
                                  width: 1.0,
                                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                                  color: AppColors.primaryWhite,
                                ),


                              const SizedBox(height: 2.0),
                              hostAsync.when(
                                data: (host) {
                                  if (host.profileImages.isEmpty) {
                                    return _buildDefaultAvatar();
                                  }

                                  return Container(
                                    height: 34.0, // Slightly smaller
                                    width: 34.0,  // Slightly smaller
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                        fit: BoxFit.cover,
                                        image: NetworkImage(host.profileImages[0]),
                                      ),
                                    ),
                                  );
                                },
                                loading: () => const SizedBox(
                                  height: 30.0,
                                  width: 30.0,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                error: (_, __) => _buildDefaultAvatar(),
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
          ],
        ),
      ),
    );
  }

  Widget _buildGuestItem(BuildContext context, WidgetRef ref, String userId) {
    final userAsync = ref.watch(userByIdProvider(userId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0), // Reduced padding
      child: userAsync.when(
        data: (user) {
          if (user.profileImages.isEmpty) {
            return _buildDefaultAvatar();
          }

          return Container(
            height: 34.0, // Slightly smaller
            width: 34.0,  // Slightly smaller
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                fit: BoxFit.cover,
                image: NetworkImage(user.profileImages[0]),
              ),
            ),
          );
        },
        loading: () => const SizedBox(
          height: 34.0,
          width: 34.0,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
        error: (_, __) => _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      height: 34.0, // Slightly smaller
      width: 34.0,  // Slightly smaller
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.grayBorder,
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 16, // Smaller icon
      ),
    );
  }
}