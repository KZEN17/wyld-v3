// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/data/models/event_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/event_controller.dart';
import '../controllers/join_request_controller.dart';

class ChosenEventDetails extends ConsumerStatefulWidget {
  final String eventId;

  const ChosenEventDetails({super.key, required this.eventId});

  @override
  ConsumerState<ChosenEventDetails> createState() => _ChosenEventDetailsState();
}

class _ChosenEventDetailsState extends ConsumerState<ChosenEventDetails> {
  bool requestSent = false;

  @override
  Widget build(BuildContext context) {
    final eventAsyncValue = ref.watch(eventProvider(widget.eventId));
    final hasPendingRequestAsyncValue = ref.watch(
      hasPendingRequestProvider(widget.eventId),
    );
    final currentUser = ref.watch(authControllerProvider);

    return Scaffold(
      body: eventAsyncValue.when(
        data: (event) {
          return hasPendingRequestAsyncValue.when(
            data: (hasPendingRequest) {
              return _buildEventDetailsView(
                context,
                event,
                hasPendingRequest,
                currentUser.value?.id ?? '',
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEventDetailsView(
    BuildContext context,
    EventModel event,
    bool hasPendingRequest,
    String currentUserId,
  ) {
    final isHost = event.hostId == currentUserId;
    final isAttending = event.guestsId.contains(currentUserId);
    final showJoinButton =
        !isHost && !isAttending && !hasPendingRequest && !requestSent;

    return Stack(
      children: [
        ListView(
          children: [
            _buildEventHeader(event),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 15.0,
              ),
              child: Text(
                event.eventTitle,
                style: const TextStyle(
                  color: AppColors.primaryWhite,
                  fontSize: 32.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _buildEventActionBar(),
            _buildEventLocation(event),
            const Divider(color: AppColors.secondaryBackground, thickness: 1),
            _buildEventDateTime(event),
            const Divider(color: AppColors.secondaryBackground, thickness: 1),
            _buildEventDescription(event),
            const Divider(color: AppColors.secondaryBackground, thickness: 1),
            if (!isHost) _buildHostInfo(event),
            _buildGuestList(event, isHost),
            const Divider(color: AppColors.secondaryBackground, thickness: 1),
            _buildComments(),
            const SizedBox(height: 100), // Space for bottom sheet
          ],
        ),
        if (showJoinButton)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildJoinRequestButton(event),
          ),
      ],
    );
  }

  Widget _buildEventHeader(EventModel event) {
    return Stack(
      children: [
        SizedBox(
          height: 200,
          width: double.infinity,
          child:
              event.venueImages.isNotEmpty
                  ? Image.network(event.venueImages[0], fit: BoxFit.cover)
                  : Container(
                    color: AppColors.secondaryBackground,
                    child: const Center(
                      child: Icon(
                        Icons.image,
                        size: 60,
                        color: AppColors.grayBorder,
                      ),
                    ),
                  ),
        ),
        Positioned(
          top: 20,
          left: 20,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionItem(Icons.share, 'Share'),
          _buildActionItem(Icons.bookmark_border, 'Save'),
          _buildActionItem(Icons.report_outlined, 'Report'),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryWhite),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(color: AppColors.primaryWhite, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEventLocation(EventModel event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 15.0),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppColors.primaryWhite),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.nameOfVenue,
                  style: const TextStyle(
                    color: AppColors.primaryWhite,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  event.venueAddress,
                  style: const TextStyle(
                    color: AppColors.secondaryWhite,
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDateTime(EventModel event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 15.0),
      child: Row(
        children: [
          const Icon(Icons.watch_later, color: AppColors.primaryWhite),
          const SizedBox(width: 10),
          Text(
            formatDate(event.eventDateTime),
            style: const TextStyle(
              color: AppColors.primaryWhite,
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDescription(EventModel event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About this event',
            style: TextStyle(
              color: AppColors.primaryWhite,
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            event.eventDescription,
            style: const TextStyle(
              color: AppColors.primaryWhite,
              fontSize: 16.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostInfo(EventModel event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Meet your host',
            style: TextStyle(
              color: AppColors.primaryWhite,
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          // Host card would go here, typically with profile image and name
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.grayBorder,
                  child: Icon(Icons.person, color: AppColors.primaryWhite),
                ),
                SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Host Name',
                      style: TextStyle(
                        color: AppColors.primaryWhite,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 14),
                        SizedBox(width: 5),
                        Text(
                          '4.8 (7 reviews)',
                          style: TextStyle(
                            color: AppColors.secondaryWhite,
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.secondaryBackground, thickness: 1),
        ],
      ),
    );
  }

  Widget _buildGuestList(EventModel event, bool isHost) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Guests (${event.guestsId.length})',
            style: const TextStyle(
              color: AppColors.primaryWhite,
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          // Guest list would go here
          if (event.guestsId.isEmpty)
            const Text(
              'No guests have joined yet.',
              style: TextStyle(color: AppColors.secondaryWhite, fontSize: 16.0),
            ),
          if (isHost)
            const Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Text(
                'Pending Requests',
                style: TextStyle(
                  color: AppColors.primaryWhite,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComments() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comments',
            style: TextStyle(
              color: AppColors.primaryWhite,
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          // Comment list would go here
          const Text(
            'No comments yet.',
            style: TextStyle(color: AppColors.secondaryWhite, fontSize: 16.0),
          ),
          const SizedBox(height: 20),
          // Comment input field
          TextField(
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              hintStyle: const TextStyle(color: AppColors.secondaryWhite),
              filled: true,
              fillColor: AppColors.secondaryBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: AppColors.primaryPink),
                onPressed: () {},
              ),
            ),
            style: const TextStyle(color: AppColors.primaryWhite),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinRequestButton(EventModel event) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primaryBackground,
        border: Border(
          top: BorderSide(color: AppColors.secondaryBackground, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Price per person',
                  style: TextStyle(
                    color: AppColors.secondaryWhite,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '\$${event.priceMen.toStringAsFixed(0)} Men',
                      style: const TextStyle(
                        color: AppColors.primaryWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '\$${event.priceWomen.toStringAsFixed(0)} Women',
                      style: const TextStyle(
                        color: AppColors.primaryWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () => _sendJoinRequest(event),
            child: const Text('Request to Join'),
          ),
        ],
      ),
    );
  }

  void _sendJoinRequest(EventModel event) async {
    final currentUser = ref.read(authControllerProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to join an event')),
      );
      return;
    }

    try {
      await ref
          .read(joinRequestControllerProvider)
          .sendJoinRequest(event.eventId, event.hostId, currentUser.id);

      setState(() {
        requestSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending request: $e')));
    }
  }
}

// Helper function to format date
String formatDate(DateTime date) {
  final months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final hour = date.hour > 12 ? date.hour - 12 : date.hour;
  final amPm = date.hour >= 12 ? 'PM' : 'AM';

  return '${date.day} ${months[date.month]}, $hour:${date.minute.toString().padLeft(2, '0')} $amPm';
}
