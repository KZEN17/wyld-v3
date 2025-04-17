import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/models/join_request_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../repositories/join_request_repository.dart';

// Provider for pending requests for the current host
final hostPendingRequestsProvider = StreamProvider<List<JoinRequest>>((
  ref,
) async* {
  final authState = ref.watch(authControllerProvider);

  if (authState.hasValue && authState.value != null) {
    final hostId = authState.value!.id;
    final joinRequestRepository = ref.watch(joinRequestRepositoryProvider);

    // Initial load
    List<JoinRequest> requests = await joinRequestRepository
        .getHostPendingRequests(hostId);
    yield requests;

    // TODO: Implement real-time updates with Appwrite Realtime
    // For now we'll simulate polling
    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      requests = await joinRequestRepository.getHostPendingRequests(hostId);
      yield requests;
    }
  } else {
    yield [];
  }
});

// Provider for requests for a specific event
final eventRequestsProvider = FutureProvider.family<List<JoinRequest>, String>((
  ref,
  eventId,
) {
  final joinRequestRepository = ref.watch(joinRequestRepositoryProvider);
  return joinRequestRepository.getEventRequests(eventId);
});

// Provider to check if the current user has a pending request for an event
final hasPendingRequestProvider = FutureProvider.family<bool, String>((
  ref,
  eventId,
) async {
  final authState = ref.watch(authControllerProvider);
  if (authState.hasValue && authState.value != null) {
    final userId = authState.value!.id;
    final joinRequestRepository = ref.watch(joinRequestRepositoryProvider);
    return joinRequestRepository.userHasPendingRequest(userId, eventId);
  }
  return false;
});

class JoinRequestController {
  final JoinRequestRepository _joinRequestRepository;

  JoinRequestController(this._joinRequestRepository);

  // Send a join request
  Future<void> sendJoinRequest(
    String eventId,
    String hostId,
    String userId,
  ) async {
    try {
      await _joinRequestRepository.sendJoinRequest(eventId, hostId, userId);
    } catch (e) {
      rethrow;
    }
  }

  // Update request status (accept/reject)
  Future<void> updateRequestStatus(String requestId, String newStatus) async {
    try {
      await _joinRequestRepository.updateRequestStatus(requestId, newStatus);
    } catch (e) {
      rethrow;
    }
  }
}

final joinRequestControllerProvider = Provider((ref) {
  final joinRequestRepository = ref.watch(joinRequestRepositoryProvider);
  return JoinRequestController(joinRequestRepository);
});
