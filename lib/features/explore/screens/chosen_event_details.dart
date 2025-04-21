// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/data/models/comment_model.dart';
import '../../../shared/data/models/event_model.dart';
import '../../../shared/data/models/join_request_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../bookings/controllers/event_controller.dart';
import '../../bookings/controllers/join_request_controller.dart';
import '../../bookings/repositories/join_request_repository.dart';
import '../controllers/comments_controller.dart';

class ChosenEventDetails extends ConsumerStatefulWidget {
  final String eventId;

  const ChosenEventDetails({super.key, required this.eventId});

  @override
  ConsumerState<ChosenEventDetails> createState() => _ChosenEventDetailsState();
}

class _ChosenEventDetailsState extends ConsumerState<ChosenEventDetails> {
  final TextEditingController _commentController = TextEditingController();
  bool requestSent = false;
  bool isLoadingPendingRequests = false;
  List<JoinRequest> pendingRequests = [];

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingRequests() async {
    final eventAsync = ref.read(eventProvider(widget.eventId));
    final event = await eventAsync.when(
      data: (event) => event,
      loading: () => null,
      error: (_, __) => null,
    );

    if (event != null) {
      setState(() {
        isLoadingPendingRequests = true;
      });

      try {
        final authState = ref.read(authControllerProvider);
        final user = authState.value;

        if (user != null && event.hostId == user.id) {
          final requests = await ref
              .read(joinRequestRepositoryProvider)
              .getEventRequests(widget.eventId);

          final pending =
              requests.where((req) => req.status == 'pending').toList();

          setState(() {
            pendingRequests = pending;
          });
        }
      } catch (e) {
        // Handle error
        debugPrint('Error loading pending requests: $e');
      } finally {
        setState(() {
          isLoadingPendingRequests = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventAsyncValue = ref.watch(eventProvider(widget.eventId));
    final hasPendingRequestAsyncValue = ref.watch(hasPendingRequestProvider(widget.eventId));
    final currentUser = ref.watch(authControllerProvider);
    final commentsAsync = ref.watch(eventCommentsProvider(widget.eventId));

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: eventAsyncValue.when(
        data: (event) {
          return hasPendingRequestAsyncValue.when(
            data: (hasPendingRequest) {
              return _buildEventDetailsView(
                context,
                event,
                hasPendingRequest,
                currentUser.value?.id ?? '',
                commentsAsync,
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
    AsyncValue<List<Comment>> commentsAsync,
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
            if (!isHost) _buildHostInfo(ref, event),
            _buildGuestList(event, isHost),
            if (isHost && pendingRequests.isNotEmpty)
              _buildPendingRequestsSection(),
            const Divider(color: AppColors.secondaryBackground, thickness: 1),
            _buildCommentsSection(commentsAsync, currentUserId),
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
                  ? Image.network(
                    event.venueImages[0],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) {
                      return Container(
                        color: AppColors.secondaryBackground,
                        child: const Icon(
                          Icons.broken_image,
                          size: 60,
                          color: AppColors.grayBorder,
                        ),
                      );
                    },
                  )
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
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Available seats
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_getAvailableSeats(event)} seats left',
                    style: const TextStyle(
                      color: AppColors.primaryWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Image navigation dots if multiple images
                if (event.venueImages.length > 1)
                  Row(
                    children: List.generate(
                      event.venueImages.length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              index == 0
                                  ? AppColors.primaryWhite
                                  : AppColors.primaryWhite.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _getAvailableSeats(EventModel event) {
    final totalSeats =
        (event.numberOfGuests['men'] ?? 0) +
        (event.numberOfGuests['women'] ?? 0);
    return totalSeats - event.guestsId.length;
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
            _formatDate(event.eventDateTime),
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

  String _formatDate(DateTime date) {
    return DateFormat('EEE, MMM d, yyyy • h:mm a').format(date);
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

  Widget _buildHostInfo(WidgetRef ref, EventModel event) {
    final hostAsync = ref.watch(userByIdProvider(event.hostId));

    return hostAsync.when(
      data:
          (host) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 15.0,
            ),
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
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: AppColors.grayBorder,
                        backgroundImage: NetworkImage(host.profileImages[0]),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            host.name,
                            style: const TextStyle(
                              color: AppColors.primaryWhite,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 14,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '4.8 (7 reviews)', // You could later fetch dynamic ratings here too
                                style: const TextStyle(
                                  color: AppColors.secondaryWhite,
                                  fontSize: 14.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          // Implement message host functionality
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPink,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Message'),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  color: AppColors.secondaryBackground,
                  thickness: 1,
                ),
              ],
            ),
          ),
      loading:
          () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
      error:
          (err, _) => const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Failed to load host info'),
          ),
    );
  }

  Widget _buildGuestList(EventModel event, bool isHost) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Guests (${event.guestsId.length})',
                style: const TextStyle(
                  color: AppColors.primaryWhite,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (event.guestsId.isNotEmpty)
                TextButton(
                  onPressed: () {
                    // View all guests
                  },
                  child: const Text(
                    'View all',
                    style: TextStyle(
                      color: AppColors.primaryPink,
                      fontSize: 14.0,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (event.guestsId.isEmpty)
            const Text(
              'No guests have joined yet.',
              style: TextStyle(color: AppColors.secondaryWhite, fontSize: 16.0),
            )
          else
            SizedBox(
              height: 80, // Increased height to accommodate guest names
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: event.guestsId.length > 5 ? 5 : event.guestsId.length,
                itemBuilder: (context, index) {
                  final userId = event.guestsId[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: _buildGuestAvatar(userId),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGuestAvatar(String userId) {
    // Use the userByIdProvider to fetch user data
    final userAsync = ref.watch(userByIdProvider(userId));

    return userAsync.when(
      data: (user) => Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.grayBorder,
            backgroundImage: user.profileImages.isNotEmpty
                ? NetworkImage(user.profileImages[0])
                : null,
            child: user.profileImages.isEmpty
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: Text(
              user.name,
              style: const TextStyle(
                color: AppColors.secondaryWhite,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      loading: () => const Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.secondaryBackground,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPink),
              ),
            ),
          ),
          SizedBox(height: 4),
          SizedBox(
            width: 60,
            height: 12,
          ),
        ],
      ),
      error: (error, stack) => const Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.secondaryBackground,
            child: Icon(Icons.error_outline, color: Colors.red),
          ),
          SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: Text(
              'Error',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pending Requests',
            style: TextStyle(
              color: AppColors.primaryWhite,
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          if (isLoadingPendingRequests)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryPink,
                  ),
                ),
              ),
            )
          else if (pendingRequests.isEmpty)
            const Text(
              'No pending requests.',
              style: TextStyle(color: AppColors.secondaryWhite, fontSize: 14),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pendingRequests.length,
              itemBuilder: (context, index) {
                final request = pendingRequests[index];
                return _buildRequestCard(ref, request);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(WidgetRef ref, JoinRequest request) {
    final userAsync = ref.watch(userByIdProvider(request.userId));

    return userAsync.when(
      data:
          (user) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.grayBorder,
                  backgroundImage: NetworkImage(user.profileImages[0]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
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
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                      onPressed: () => _respondToRequest(request, 'accepted'),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.cancel_outlined,
                        color: Colors.red,
                      ),
                      onPressed: () => _respondToRequest(request, 'rejected'),
                    ),
                  ],
                ),
              ],
            ),
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error loading user'),
    );
  }

  Future<void> _respondToRequest(JoinRequest request, String status) async {
    try {
      // Update request status
      await ref
          .read(joinRequestControllerProvider)
          .updateRequestStatus(request.requestId, status);

      // If accepted, add user to event guests
      if (status == 'accepted') {
        final eventAsync = ref.read(eventProvider(widget.eventId));
        final event = await eventAsync.when(
          data: (event) => event,
          loading: () => null,
          error: (_, __) => null,
        );

        if (event != null) {
          final updatedGuestsId = [...event.guestsId, request.userId];
          await ref
              .read(eventControllerProvider.notifier)
              .updateEventField(widget.eventId, 'guestsId', updatedGuestsId);
        }
      }

      // Refresh pending requests
      await _loadPendingRequests();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request ${status == 'accepted' ? 'accepted' : 'rejected'}',
          ),
          backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildCommentsSection(
    AsyncValue<List<Comment>> commentsAsync,
    String currentUserId,
  ) {
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
          // Comment input field
          Container(
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: _commentController,
              style: const TextStyle(color: AppColors.primaryWhite),
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                hintStyle: const TextStyle(color: AppColors.secondaryWhite),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primaryPink),
                  onPressed: () => _submitComment(currentUserId),
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          // Comments list
          commentsAsync.when(
            data: (comments) {
              if (comments.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'No comments yet. Be the first to comment!',
                      style: TextStyle(color: AppColors.secondaryWhite),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return _buildCommentItem(comment, currentUserId);
                },
              );
            },
            loading:
                () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryPink,
                      ),
                    ),
                  ),
                ),
            error:
                (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'Error loading comments: $error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Comment comment, String currentUserId) {
    final isCurrentUser = comment.userId == currentUserId;
    final timeAgo = _getTimeAgo(comment.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar
          comment.userImage.isNotEmpty
              ? CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(comment.userImage),
              )
              : const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryPink,
                child: Icon(Icons.person, color: Colors.white, size: 16),
              ),
          const SizedBox(width: 12),
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: TextStyle(
                        color:
                            isCurrentUser
                                ? AppColors.primaryPink
                                : AppColors.primaryWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo,
                      style: const TextStyle(
                        color: AppColors.secondaryWhite,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: const TextStyle(color: AppColors.primaryWhite),
                ),
              ],
            ),
          ),
          // Delete button for current user's comments
          if (isCurrentUser)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 16,
              ),
              onPressed: () => _deleteComment(comment.id),
            ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, yyyy').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  void _submitComment(String currentUserId) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final authState = ref.read(authControllerProvider);
    final user = authState.value;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to comment')),
      );
      return;
    }

    try {
      final comment = Comment.create(
        eventId: widget.eventId,
        userId: user.id,
        userName: user.name,
        userImage:
            user.profileImages.isNotEmpty
                ? user.profileImages[0]
                : (user.userImages.isNotEmpty ? user.userImages[0] : ''),
        text: text,
      );

      await ref
          .read(eventCommentsProvider(widget.eventId).notifier)
          .addComment(comment);
      await ref
          .read(eventCommentsProvider(widget.eventId).notifier)
          .getComments();

      // Clear the input field
      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error posting comment: $e')));
    }
  }

  void _deleteComment(String commentId) async {
    try {
      await ref
          .read(eventCommentsProvider(widget.eventId).notifier)
          .deleteComment(commentId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment deleted')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting comment: $e')));
    }
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
                    Row(
                      children: [
                        SizedBox(
                          height: 20.0,
                          width: 20.0,
                          child: Image.asset('assets/icons/male.png'),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '\$${event.priceMen.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.primaryWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Row(
                      children: [
                        SizedBox(
                          height: 20.0,
                          width: 20.0,
                          child: Image.asset('assets/icons/female.png'),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '\$${event.priceWomen.toStringAsFixed(0)}',
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
    final authState = ref.read(authControllerProvider);
    final currentUser = authState.value;

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
        const SnackBar(
          content: Text('Request sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending request: $e')));
    }
  }
}
