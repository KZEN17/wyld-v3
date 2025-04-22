// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// import '../../../core/constants/app_constants.dart';
// import '../../../core/services/realtime_service.dart';
// import '../../../shared/data/models/join_request_model.dart';
// import '../../auth/controllers/auth_controller.dart';
// import '../repositories/join_request_repository.dart';
//
// // Provider for pending requests for the current host with real-time updates
// final hostPendingRequestsProvider = StateNotifierProvider<HostPendingRequestsController, AsyncValue<List<JoinRequest>>>((ref) {
//   final authState = ref.watch(authControllerProvider);
//   final joinRequestRepository = ref.watch(joinRequestRepositoryProvider);
//   final realtimeService = ref.watch(realtimeServiceProvider);
//
//   if (authState.hasValue && authState.value != null) {
//     final hostId = authState.value!.id;
//     return HostPendingRequestsController(joinRequestRepository, realtimeService, hostId);
//   }
//
//   // Return a controller with empty state if not authenticated
//   return HostPendingRequestsController(joinRequestRepository, realtimeService, '');
// });
//
// // Provider for requests for a specific event with real-time updates
// final eventRequestsProvider = StateNotifierProvider.family<EventRequestsController, AsyncValue<List<JoinRequest>>, String>((ref, eventId) {
//   final joinRequestRepository = ref.watch(joinRequestRepositoryProvider);
//   final realtimeService = ref.watch(realtimeServiceProvider);
//   return EventRequestsController(joinRequestRepository, realtimeService, eventId);
// });
//
// // Provider to check if the current user has a pending request for an event
// final hasPendingRequestProvider = StateNotifierProvider.family<UserPendingRequestController, AsyncValue<bool>, String>((ref, eventId) {
//   final authState = ref.watch(authControllerProvider);
//   final joinRequestRepository = ref.watch(joinRequestRepositoryProvider);
//   final realtimeService = ref.watch(realtimeServiceProvider);
//
//   if (authState.hasValue && authState.value != null) {
//     final userId = authState.value!.id;
//     return UserPendingRequestController(joinRequestRepository, realtimeService, userId, eventId);
//   }
//
//   // Return a controller with false state if not authenticated
//   return UserPendingRequestController(joinRequestRepository, realtimeService, '', eventId);
// });
//
// // Controller for hosting pending requests
// class HostPendingRequestsController extends StateNotifier<AsyncValue<List<JoinRequest>>> {
//   final JoinRequestRepository _joinRequestRepository;
//   final RealtimeService _realtimeService;
//   final String _hostId;
//   StreamSubscription? _subscription;
//
//   HostPendingRequestsController(this._joinRequestRepository, this._realtimeService, this._hostId)
//       : super(const AsyncValue.loading()) {
//     if (_hostId.isNotEmpty) {
//       _loadHostPendingRequests();
//       _subscribeToJoinRequests();
//     } else {
//       state = const AsyncValue.data([]);
//     }
//   }
//
//   Future<void> _loadHostPendingRequests() async {
//     try {
//       final requests = await _joinRequestRepository.getHostPendingRequests(_hostId);
//       state = AsyncValue.data(requests);
//     } catch (e, stackTrace) {
//       state = AsyncValue.error(e, stackTrace);
//     }
//   }
//
//   void _subscribeToJoinRequests() {
//     try {
//       _subscription = _realtimeService
//           .subscribeToCollection(AppwriteConstants.joinRequestsCollection)
//           .listen((event) {
//         // Filter events related to this host
//         if (event.payload['hostId'] == _hostId) {
//           if (kDebugMode) {
//             print('Join request update for host: $_hostId');
//           }
//           _loadHostPendingRequests();
//         }
//       });
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error subscribing to join requests: $e');
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _subscription?.cancel();
//     super.dispose();
//   }
// }
//
// // Controller for event requests
// class EventRequestsController extends StateNotifier<AsyncValue<List<JoinRequest>>> {
//   final JoinRequestRepository _joinRequestRepository;
//   final RealtimeService _realtimeService;
//   final String _eventId;
//   StreamSubscription? _subscription;
//
//   EventRequestsController(this._joinRequestRepository, this._realtimeService, this._eventId)
//       : super(const AsyncValue.loading()) {
//     _loadEventRequests();
//     _subscribeToEventRequests();
//   }
//
//   Future<void> _loadEventRequests() async {
//     try {
//       final requests = await _joinRequestRepository.getEventRequests(_eventId);
//       state = AsyncValue.data(requests);
//     } catch (e, stackTrace) {
//       state = AsyncValue.error(e, stackTrace);
//     }
//   }
//
//   void _subscribeToEventRequests() {
//     try {
//       _subscription = _realtimeService
//           .subscribeToCollection(AppwriteConstants.joinRequestsCollection)
//           .listen((event) {
//         // Filter events related to this event
//         if (event.payload['eventId'] == _eventId) {
//           if (kDebugMode) {
//             print('Join request update for event: $_eventId');
//           }
//           _loadEventRequests();
//         }
//       });
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error subscribing to event requests: $e');
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _subscription?.cancel();
//     super.dispose();
//   }
// }
//
// // Controller for user pending request
// class UserPendingRequestController extends StateNotifier<AsyncValue<bool>> {
//   final JoinRequestRepository _joinRequestRepository;
//   final RealtimeService _realtimeService;
//   final String _userId;
//   final String _eventId;
//   StreamSubscription? _subscription;
//
//   UserPendingRequestController(this._joinRequestRepository, this._realtimeService, this._userId, this._eventId)
//       : super(const AsyncValue.loading()) {
//     if (_userId.isNotEmpty) {
//       _checkUserPendingRequest();
//       _subscribeToUserRequests();
//     } else {
//       state = const AsyncValue.data(false);
//     }
//   }
//
//   Future<void> _checkUserPendingRequest() async {
//     try {
//       final hasPendingRequest = await _joinRequestRepository.userHasPendingRequest(_userId, _eventId);
//       state = AsyncValue.data(hasPendingRequest);
//     } catch (e, stackTrace) {
//       state = AsyncValue.error(e, stackTrace);
//     }
//   }
//
//   void _subscribeToUserRequests() {
//     try {
//       _subscription = _realtimeService
//           .subscribeToCollection(AppwriteConstants.joinRequestsCollection)
//           .listen((event) {
//         // Check if this update is related to the user and event we're monitoring
//         final payload = event.payload;
//         if (payload['userId'] == _userId && payload['eventId'] == _eventId) {
//           if (kDebugMode) {
//             print('User request update for user: $_userId and event: $_eventId');
//           }
//           _checkUserPendingRequest();
//         }
//       });
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error subscribing to user requests: $e');
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _subscription?.cancel();
//     super.dispose();
//   }
// }
//
// class JoinRequestController {
//   final JoinRequestRepository _joinRequestRepository;
//
//   JoinRequestController(this._joinRequestRepository);
//
//   // Send a join request
//   Future<void> sendJoinRequest(
//       String eventId,
//       String hostId,
//       String userId,
//       ) async {
//     try {
//       await _joinRequestRepository.sendJoinRequest(eventId, hostId, userId);
//       // The real-time controllers will update automatically
//     } catch (e) {
//       rethrow;
//     }
//   }
//
//   // Update request status (accept/reject)
//   Future<void> updateRequestStatus(String requestId, String newStatus) async {
//     try {
//       await _joinRequestRepository.updateRequestStatus(requestId, newStatus);
//       // The real-time controllers will update automatically
//     } catch (e) {
//       rethrow;
//     }
//   }
// }
//
// final joinRequestControllerProvider = Provider((ref) {
//   final joinRequestRepository = ref.watch(joinRequestRepositoryProvider);
//   return JoinRequestController(joinRequestRepository);
// });
// Update to lib/features/bookings/controllers/join_request_controller.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/realtime_service.dart';
import '../../../shared/data/models/join_request_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../repositories/join_request_repository.dart';
import '../../../shared/data/models/event_model.dart';
import '../controllers/event_controller.dart';

// Provider for pending requests for the current host with real-time updates
final hostPendingRequestsProvider = StateNotifierProvider<HostPendingRequestsController, AsyncValue<List<JoinRequest>>>((ref) {
  final authState = ref.watch(authControllerProvider);
  final joinRequestRepository = ref.watch(joinRequestRepositoryProvider);
  final realtimeService = ref.watch(realtimeServiceProvider);

  if (authState.hasValue && authState.value != null) {
    final hostId = authState.value!.id;
    return HostPendingRequestsController(joinRequestRepository, realtimeService, hostId);
  }

  // Return a controller with empty state if not authenticated
  return HostPendingRequestsController(joinRequestRepository, realtimeService, '');
});

// Provider for requests for a specific event with real-time updates
final eventRequestsProvider = StateNotifierProvider.family<EventRequestsController, AsyncValue<List<JoinRequest>>, String>((ref, eventId) {
  final joinRequestRepository = ref.watch(joinRequestRepositoryProvider);
  final realtimeService = ref.watch(realtimeServiceProvider);
  return EventRequestsController(joinRequestRepository, realtimeService, eventId);
});

// Provider to check if the current user has a pending request for an event
final hasPendingRequestProvider = StateNotifierProvider.family<UserPendingRequestController, AsyncValue<bool>, String>((ref, eventId) {
  final authState = ref.watch(authControllerProvider);
  final joinRequestRepository = ref.watch(joinRequestRepositoryProvider);
  final realtimeService = ref.watch(realtimeServiceProvider);

  if (authState.hasValue && authState.value != null) {
    final userId = authState.value!.id;
    return UserPendingRequestController(joinRequestRepository, realtimeService, userId, eventId);
  }

  // Return a controller with false state if not authenticated
  return UserPendingRequestController(joinRequestRepository, realtimeService, '', eventId);
});

// Controller for hosting pending requests
class HostPendingRequestsController extends StateNotifier<AsyncValue<List<JoinRequest>>> {
  final JoinRequestRepository _joinRequestRepository;
  final RealtimeService _realtimeService;
  final String _hostId;
  StreamSubscription? _subscription;

  HostPendingRequestsController(this._joinRequestRepository, this._realtimeService, this._hostId)
      : super(const AsyncValue.loading()) {
    if (_hostId.isNotEmpty) {
      _loadHostPendingRequests();
      _subscribeToJoinRequests();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> _loadHostPendingRequests() async {
    try {
      final requests = await _joinRequestRepository.getHostPendingRequests(_hostId);
      state = AsyncValue.data(requests);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void _subscribeToJoinRequests() {
    try {
      _subscription = _realtimeService
          .subscribeToCollection(AppwriteConstants.joinRequestsCollection)
          .listen((event) {
        // Filter events related to this host
        if (event.payload['hostId'] == _hostId) {
          if (kDebugMode) {
            print('Join request update for host: $_hostId');
          }
          _loadHostPendingRequests();
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to join requests: $e');
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

// Controller for event requests
class EventRequestsController extends StateNotifier<AsyncValue<List<JoinRequest>>> {
  final JoinRequestRepository _joinRequestRepository;
  final RealtimeService _realtimeService;
  final String _eventId;
  StreamSubscription? _subscription;

  EventRequestsController(this._joinRequestRepository, this._realtimeService, this._eventId)
      : super(const AsyncValue.loading()) {
    _loadEventRequests();
    _subscribeToEventRequests();
  }

  Future<void> _loadEventRequests() async {
    try {
      final requests = await _joinRequestRepository.getEventRequests(_eventId);
      state = AsyncValue.data(requests);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void _subscribeToEventRequests() {
    try {
      _subscription = _realtimeService
          .subscribeToCollection(AppwriteConstants.joinRequestsCollection)
          .listen((event) {
        // Filter events related to this event
        if (event.payload['eventId'] == _eventId) {
          if (kDebugMode) {
            print('Join request update for event: $_eventId');
          }
          _loadEventRequests();
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to event requests: $e');
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

// Controller for user pending request
class UserPendingRequestController extends StateNotifier<AsyncValue<bool>> {
  final JoinRequestRepository _joinRequestRepository;
  final RealtimeService _realtimeService;
  final String _userId;
  final String _eventId;
  StreamSubscription? _subscription;

  UserPendingRequestController(this._joinRequestRepository, this._realtimeService, this._userId, this._eventId)
      : super(const AsyncValue.loading()) {
    if (_userId.isNotEmpty) {
      _checkUserPendingRequest();
      _subscribeToUserRequests();
    } else {
      state = const AsyncValue.data(false);
    }
  }

  Future<void> _checkUserPendingRequest() async {
    try {
      final hasPendingRequest = await _joinRequestRepository.userHasPendingRequest(_userId, _eventId);
      state = AsyncValue.data(hasPendingRequest);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void _subscribeToUserRequests() {
    try {
      _subscription = _realtimeService
          .subscribeToCollection(AppwriteConstants.joinRequestsCollection)
          .listen((event) {
        // Check if this update is related to the user and event we're monitoring
        final payload = event.payload;
        if (payload['userId'] == _userId && payload['eventId'] == _eventId) {
          if (kDebugMode) {
            print('User request update for user: $_userId and event: $_eventId');
          }
          _checkUserPendingRequest();
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to user requests: $e');
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class JoinRequestController {
  final JoinRequestRepository _joinRequestRepository;
  final Ref _ref;

  JoinRequestController(this._joinRequestRepository, this._ref);

  // Send a join request
  Future<void> sendJoinRequest(
      String eventId,
      String hostId,
      String userId,
      ) async {
    try {
      await _joinRequestRepository.sendJoinRequest(eventId, hostId, userId);

      // Send notification to the host
      final notificationController = _ref.read(userNotificationsProvider.notifier);
      final authState = _ref.read(authControllerProvider);
      final eventAsync = _ref.read(eventProvider(eventId));

      if (authState.hasValue && authState.value != null && eventAsync.hasValue) {
        final currentUser = authState.value!;
        final event = eventAsync.value!;

        await notificationController.sendJoinRequestNotification(
          userId: hostId,
          senderId: userId,
          senderName: currentUser.name,
          eventId: eventId,
          eventTitle: event.eventTitle,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Update request status (accept/reject)
  Future<void> updateRequestStatus(String requestId, String newStatus) async {
    try {
      // Get the request details before updating
      final requests = await _joinRequestRepository.getAllRequests();
      final request = requests.firstWhere((r) => r.requestId == requestId,
          orElse: () => throw Exception('Request not found'));

      // Update the request status
      await _joinRequestRepository.updateRequestStatus(requestId, newStatus);

      // Get required data for notifications
      final notificationController = _ref.read(userNotificationsProvider.notifier);
      final hostAsync = _ref.read(userByIdProvider(request.hostId));
      final eventAsync = _ref.read(eventProvider(request.eventId));

      if (hostAsync.hasValue && eventAsync.hasValue) {
        final host = hostAsync.value!;
        final event = eventAsync.value!;

        // Send appropriate notification
        if (newStatus == 'accepted') {
          await notificationController.sendJoinApprovedNotification(
            userId: request.userId,
            hostId: request.hostId,
            hostName: host.name,
            eventId: request.eventId,
            eventTitle: event.eventTitle,
          );
        } else if (newStatus == 'rejected') {
          await notificationController.sendJoinRejectedNotification(
            userId: request.userId,
            hostId: request.hostId,
            hostName: host.name,
            eventId: request.eventId,
            eventTitle: event.eventTitle,
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}

final joinRequestControllerProvider = Provider((ref) {
  final joinRequestRepository = ref.watch(joinRequestRepositoryProvider);
  return JoinRequestController(joinRequestRepository, ref);
});