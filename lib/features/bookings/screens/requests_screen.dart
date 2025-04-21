import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wyld/features/bookings/screens/widgets/widgets.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/data/models/join_request_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../bookings/controllers/event_controller.dart';
import '../../bookings/controllers/join_request_controller.dart';
import '../repositories/join_request_repository.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = false;

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
    final pendingRequestsAsync = ref.watch(hostPendingRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        title: const Text(
          'Requests',
          style: TextStyle(
            color: AppColors.primaryWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryPink,
          labelColor: AppColors.primaryPink,
          unselectedLabelColor: AppColors.secondaryWhite,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Accepted'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pending Requests Tab
          pendingRequestsAsync.when(
            data: (requests) {
              if (requests.isEmpty) {
                return _buildEmptyState('No pending requests');
              }
              return _buildRequestsList(requests, 'pending');
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error: $error', style: const TextStyle(color: Colors.white)),
            ),
          ),

          // Accepted Requests Tab
          _buildFilteredRequestsList('accepted'),

          // Rejected Requests Tab
          _buildFilteredRequestsList('rejected'),
        ],
      ),
    );
  }

  Widget _buildFilteredRequestsList(String status) {
    final requestsAsync = ref.watch(filteredRequestsProvider(status));

    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return _buildEmptyState('No $status requests');
        }
        return _buildRequestsList(requests, status);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error', style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildRequestsList(List<JoinRequest> requests, String status) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return RequestCard(
          request: request,
          onAccept: status == 'pending' ? () => _respondToRequest(request, 'accepted') : null,
          onReject: status == 'pending' ? () => _respondToRequest(request, 'rejected') : null,
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inbox_outlined,
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
        ],
      ),
    );
  }

  Future<void> _respondToRequest(JoinRequest request, String status) async {
    setState(() {
      isLoading = true;
    });

    try {
      // Update request status
      await ref.read(joinRequestControllerProvider).updateRequestStatus(
        request.requestId,
        status,
      );

      // If accepted, add user to event guests
      if (status == 'accepted') {
        final eventAsync = ref.read(eventProvider(request.eventId));
        final event = await eventAsync.when(
          data: (event) => event,
          loading: () => null,
          error: (_, __) => null,
        );

        if (event != null) {
          final updatedGuestsId = [...event.guestsId, request.userId];
          await ref
              .read(eventControllerProvider.notifier)
              .updateEventField(request.eventId, 'guestsId', updatedGuestsId);
        }
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request ${status == 'accepted' ? 'accepted' : 'rejected'}'),
            backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}

// Provider for filtered requests by status
final filteredRequestsProvider = StateNotifierProvider.family<FilteredRequestsController, AsyncValue<List<JoinRequest>>, String>(
      (ref, status) {
    final authState = ref.watch(authControllerProvider);
    final joinRequestRepository = ref.watch(joinRequestRepositoryProvider);

    if (authState.hasValue && authState.value != null) {
      final hostId = authState.value!.id;
      return FilteredRequestsController(joinRequestRepository, hostId, status);
    }

    return FilteredRequestsController(joinRequestRepository, '', status);
  },
);

class FilteredRequestsController extends StateNotifier<AsyncValue<List<JoinRequest>>> {
  final JoinRequestRepository _joinRequestRepository;
  final String _hostId;
  final String _status;

  FilteredRequestsController(this._joinRequestRepository, this._hostId, this._status)
      : super(const AsyncValue.loading()) {
    if (_hostId.isNotEmpty) {
      _loadFilteredRequests();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> _loadFilteredRequests() async {
    try {
      // Get all requests for this host
      final allRequests = await _joinRequestRepository.getHostAllRequests(_hostId);

      // Filter by status
      final filteredRequests = allRequests.where((req) => req.status == _status).toList();

      state = AsyncValue.data(filteredRequests);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}