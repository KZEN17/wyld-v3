import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/data/models/join_request_model.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../controllers/event_controller.dart';



class RequestCard extends ConsumerWidget {
  final JoinRequest request;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const RequestCard({
    super.key,
    required this.request,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(request.userId));
    final eventAsync = ref.watch(eventProvider(request.eventId));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Event and User Information
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Title
                eventAsync.when(
                  data: (event) => Text(
                    event.eventTitle,
                    style: const TextStyle(
                      color: AppColors.primaryWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  loading: () => const SizedBox(
                    width: 150,
                    height: 24,
                    child: LinearProgressIndicator(),
                  ),
                  error: (_, __) => const Text(
                    'Error loading event',
                    style: TextStyle(color: Colors.red),
                  ),
                ),

                const SizedBox(height: 8),

                // Event Date and Location
                eventAsync.when(
                  data: (event) => Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.secondaryWhite,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, yyyy • h:mm a').format(event.eventDateTime),
                        style: const TextStyle(
                          color: AppColors.secondaryWhite,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.secondaryWhite,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.nameOfVenue,
                          style: const TextStyle(
                            color: AppColors.secondaryWhite,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox(
                    width: double.infinity,
                    height: 16,
                    child: LinearProgressIndicator(),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 16),

                // User who requested
                userAsync.when(
                  data: (user) => Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: user.profileImages.isNotEmpty
                            ? Image.network(
                          user.profileImages[0],
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        )
                            : Container(
                          width: 40,
                          height: 40,
                          color: AppColors.grayBorder,
                          child: const Icon(
                            Icons.person,
                            color: AppColors.primaryWhite,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              color: AppColors.primaryWhite,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Requested to join',
                            style: TextStyle(
                              color: AppColors.secondaryWhite,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  loading: () => const SizedBox(
                    width: 200,
                    height: 40,
                    child: LinearProgressIndicator(),
                  ),
                  error: (_, __) => const Text(
                    'Error loading user',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons (only for pending requests)
          if (onAccept != null && onReject != null)
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.grayBorder, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: onReject,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(
                    height: 50,
                    child: VerticalDivider(
                      color: AppColors.grayBorder,
                      width: 1,
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: onAccept,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ),

          // Status badge for non-pending requests
          if (onAccept == null && onReject == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: request.status == 'accepted' ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Text(
                  request.status == 'accepted' ? 'Accepted' : 'Declined',
                  style: TextStyle(
                    color: request.status == 'accepted' ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}