// New file: lib/features/notifications/controllers/notification_controller.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/realtime_service.dart';
import '../data/models/notification_model.dart';
import '../repositories/notification_repository.dart';

// Provider for user notifications with real-time updates
final userNotificationsProvider = StateNotifierProvider<NotificationController, AsyncValue<List<NotificationModel>>>((ref) {
  final notificationRepository = ref.watch(notificationRepositoryProvider);
  final realtimeService = ref.watch(realtimeServiceProvider);
  return NotificationController(notificationRepository, realtimeService);
});

// Provider for unread notifications count
final unreadNotificationsCountProvider = FutureProvider.family<int, String>((ref, userId) {
  final notificationRepository = ref.watch(notificationRepositoryProvider);
  return notificationRepository.getUnreadNotificationsCount(userId);
});

class NotificationController extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final NotificationRepository _notificationRepository;
  final RealtimeService _realtimeService;
  StreamSubscription? _subscription;
  String? _currentUserId;

  NotificationController(this._notificationRepository, this._realtimeService)
      : super(const AsyncValue.loading());

  // Initialize with user ID
  void initialize(String userId) {
    _currentUserId = userId;
    getUserNotifications(userId);
    _subscribeToNotifications();
  }

  // Get all notifications for a user
  Future<void> getUserNotifications(String userId) async {
    state = const AsyncValue.loading();
    try {
      final notifications = await _notificationRepository.getUserNotifications(userId);
      state = AsyncValue.data(notifications);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Subscribe to real-time updates for notifications
  void _subscribeToNotifications() {
    try {
      _subscription = _realtimeService
          .subscribeToCollection('notifications') // Add this to your constants
          .listen((event) {
        if (_currentUserId == null) return;

        // Check if this notification is for the current user
        final notificationUserId = event.payload['userId'] as String?;
        if (notificationUserId == null || notificationUserId != _currentUserId) return;

        if (kDebugMode) {
          print('Notification update received');
        }

        // Refresh notifications
        getUserNotifications(_currentUserId!);
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to notifications: $e');
      }
    }
  }

  // Add a new notification
  Future<NotificationModel> addNotification(NotificationModel notification) async {
    try {
      return await _notificationRepository.addNotification(notification);
    } catch (e) {
      rethrow;
    }
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationRepository.markNotificationAsRead(notificationId);

      // Update state
      if (state.hasValue) {
        final notifications = state.value!;
        final updatedNotifications = notifications.map((notification) {
          if (notification.id == notificationId) {
            return notification.markAsRead();
          }
          return notification;
        }).toList();

        state = AsyncValue.data(updatedNotifications);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_currentUserId == null) return;

    try {
      await _notificationRepository.markAllNotificationsAsRead(_currentUserId!);

      // Update state
      if (state.hasValue) {
        final notifications = state.value!;
        final updatedNotifications = notifications.map((notification) {
          return notification.markAsRead();
        }).toList();

        state = AsyncValue.data(updatedNotifications);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Send a friend request notification
  Future<void> sendFriendRequestNotification({
    required String userId,
    required String senderId,
    required String senderName,
  }) async {
    try {
      final notification = NotificationModel.friendRequest(
        userId: userId,
        senderId: senderId,
        senderName: senderName,
      );

      await addNotification(notification);
    } catch (e) {
      if (kDebugMode) {
        print('Error sending friend request notification: $e');
      }
    }
  }

  // Send a friend accepted notification
  Future<void> sendFriendAcceptedNotification({
    required String userId,
    required String senderId,
    required String senderName,
  }) async {
    try {
      final notification = NotificationModel.friendAccepted(
        userId: userId,
        senderId: senderId,
        senderName: senderName,
      );

      await addNotification(notification);
    } catch (e) {
      if (kDebugMode) {
        print('Error sending friend accepted notification: $e');
      }
    }
  }

  // Send a join request notification
  Future<void> sendJoinRequestNotification({
    required String userId,
    required String senderId,
    required String senderName,
    required String eventId,
    required String eventTitle,
  }) async {
    try {
      final notification = NotificationModel.joinRequest(
        userId: userId,
        senderId: senderId,
        senderName: senderName,
        eventId: eventId,
        eventTitle: eventTitle,
      );

      await addNotification(notification);
    } catch (e) {
      if (kDebugMode) {
        print('Error sending join request notification: $e');
      }
    }
  }

  // Send a join approved notification
  Future<void> sendJoinApprovedNotification({
    required String userId,
    required String hostId,
    required String hostName,
    required String eventId,
    required String eventTitle,
  }) async {
    try {
      final notification = NotificationModel.joinApproved(
        userId: userId,
        hostId: hostId,
        hostName: hostName,
        eventId: eventId,
        eventTitle: eventTitle,
      );

      await addNotification(notification);
    } catch (e) {
      if (kDebugMode) {
        print('Error sending join approved notification: $e');
      }
    }
  }

  // Send a join rejected notification
  Future<void> sendJoinRejectedNotification({
    required String userId,
    required String hostId,
    required String hostName,
    required String eventId,
    required String eventTitle,
  }) async {
    try {
      final notification = NotificationModel.joinRejected(
        userId: userId,
        hostId: hostId,
        hostName: hostName,
        eventId: eventId,
        eventTitle: eventTitle,
      );

      await addNotification(notification);
    } catch (e) {
      if (kDebugMode) {
        print('Error sending join rejected notification: $e');
      }
    }
  }

  // Send a message notification
  Future<void> sendMessageNotification({
    required String userId,
    required String senderId,
    required String senderName,
    required String chatId,
    required String messagePreview,
    required bool isDirectMessage,
  }) async {
    try {
      final notification = NotificationModel.message(
        userId: userId,
        senderId: senderId,
        senderName: senderName,
        chatId: chatId,
        messagePreview: messagePreview,
        isDirectMessage: isDirectMessage,
      );

      await addNotification(notification);
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message notification: $e');
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}