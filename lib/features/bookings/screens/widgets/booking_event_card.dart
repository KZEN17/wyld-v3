import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/data/models/event_model.dart';
import '../../../auth/controllers/auth_controller.dart';

class BookingEventCard extends ConsumerWidget {
  final EventModel event;
  final bool isHost;
  final bool isPast;
  final VoidCallback onTap;

  const BookingEventCard({
    Key? key,
    required this.event,
    required this.isHost,
    required this.isPast,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalGuests = (event.numberOfGuests['men'] ?? 0) + (event.numberOfGuests['women'] ?? 0);
    final availableSpace = totalGuests - event.guestsId.length;
    final hostAsync = ref.watch(userByIdProvider(event.hostId));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Stack(
                children: [
                  // Event image or placeholder
                  SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: event.venueImages.isNotEmpty
                        ? Image.network(
                      event.venueImages[0],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) {
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
                  ),

                  // Status badge (Past, Hosting, etc.)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: _getStatusColor(),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                  // Guest count badge
                  Positioned(
                    top: 0,
                    left: 12,
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
                            event.guestsId.length.toString(),
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

            // Event details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event title
                  Text(
                    event.eventTitle,
                    style: const TextStyle(
                      color: AppColors.primaryWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Event venue
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
                          style: const TextStyle(
                            color: AppColors.secondaryWhite,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Event date
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.secondaryWhite,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('E, MMM d • h:mm a').format(event.eventDateTime),
                        style: const TextStyle(
                          color: AppColors.secondaryWhite,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Host info (if not hosting)
                  if (!isHost)
                    hostAsync.when(
                      data: (host) => Row(
                        children: [
                          const Text(
                            'Hosted by: ',
                            style: TextStyle(
                              color: AppColors.secondaryWhite,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: host.profileImages.isNotEmpty
                                  ? DecorationImage(
                                image: NetworkImage(host.profileImages[0]),
                                fit: BoxFit.cover,
                              )
                                  : null,
                              color: AppColors.grayBorder,
                            ),
                            child: host.profileImages.isEmpty
                                ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 14,
                            )
                                : null,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            host.name,
                            style: const TextStyle(
                              color: AppColors.primaryWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      loading: () => const SizedBox(
                        height: 24,
                        width: 150,
                        child: LinearProgressIndicator(),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                  // Action rows
                  const SizedBox(height: 12),
                  if (!isPast)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to chat for this event
                            Navigator.pushNamed(
                              context,
                              '/chat',
                              arguments: event.eventId,
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline, size: 16),
                          label: const Text('Chat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryPink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isHost)
                          OutlinedButton.icon(
                            onPressed: () {
                              // Edit event (for hosts)
                            },
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Edit'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryWhite,
                              side: const BorderSide(color: AppColors.primaryWhite),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
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
  }

  Color _getStatusColor() {
    if (isPast) {
      return Colors.grey;
    } else if (isHost) {
      return AppColors.primaryPink;
    } else {
      return Colors.green;
    }
  }

  String _getStatusText() {
    if (isPast) {
      return 'Ended';
    } else if (isHost) {
      return 'Hosting';
    } else {
      return 'Attending';
    }
  }
}