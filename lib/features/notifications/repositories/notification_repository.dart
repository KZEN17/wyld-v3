// New file: lib/features/notifications/repositories/notification_repository.dart

import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../data/models/notification_model.dart';

// Add this to your app_constants.dart
// static const String notificationsCollection = '6805fd2c0223c9d4300f';

final notificationRepositoryProvider = Provider((ref) {
  return NotificationRepository(
    db: Databases(
      Client()
        ..setEndpoint(AppwriteConstants.endpoint)
        ..setProject(AppwriteConstants.projectId)
        ..setSelfSigned(status: true),
    ),
  );
});

class NotificationRepository {
  final Databases _db;

  NotificationRepository({required Databases db}) : _db = db;

  // Add a new notification
  Future<NotificationModel> addNotification(NotificationModel notification) async {
    try {
      final response = await _db.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: 'notifications', // Add this to your constants
        documentId: notification.id,
        data: notification.toJson(),
      );

      return NotificationModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // Get notifications for a user
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final response = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: 'notifications', // Add this to your constants
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('timestamp'),
        ],
      );

      return response.documents
          .map((doc) => NotificationModel.fromJson(doc.data))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get unread notifications count for a user
  Future<int> getUnreadNotificationsCount(String userId) async {
    try {
      final response = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: 'notifications', // Add this to your constants
        queries: [
          Query.equal('userId', userId),
          Query.equal('isRead', false),
        ],
      );

      return response.documents.length;
    } catch (e) {
      return 0; // Return 0 if there's an error
    }
  }

  // Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _db.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: 'notifications', // Add this to your constants
        documentId: notificationId,
        data: {'isRead': true},
      );
    } catch (e) {
      rethrow;
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final notifications = await getUserNotifications(userId);
      final unreadNotifications = notifications.where((notification) => !notification.isRead).toList();

      // Update each unread notification
      for (var notification in unreadNotifications) {
        await markNotificationAsRead(notification.id);
      }
    } catch (e) {
      rethrow;
    }
  }}