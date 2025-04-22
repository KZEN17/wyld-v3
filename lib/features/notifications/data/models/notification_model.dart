// New file: lib/features/notifications/models/notification_model.dart

import 'package:uuid/uuid.dart';

enum NotificationType {
  friendRequest,
  friendAccepted,
  joinRequest,
  joinApproved,
  joinRejected,
  message,
  eventReminder,
  systemMessage,
}

class NotificationModel {
  final String id;
  final String userId; // User who receives this notification
  final String title;
  final String body;
  final NotificationType type;
  final String? senderId; // User who triggered the notification, if applicable
  final String? relatedId; // Related entity ID (event, chat, etc.)
  final DateTime timestamp;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.senderId,
    this.relatedId,
    required this.timestamp,
    this.isRead = false,
  });

  // Factory method to create a new notification
  factory NotificationModel.create({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? senderId,
    String? relatedId,
  }) {
    return NotificationModel(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      body: body,
      type: type,
      senderId: senderId,
      relatedId: relatedId,
      timestamp: DateTime.now(),
    );
  }

  // Friend request notification
  factory NotificationModel.friendRequest({
    required String userId,
    required String senderId,
    required String senderName,
  }) {
    return NotificationModel.create(
      userId: userId,
      title: 'Friend Request',
      body: '$senderName sent you a friend request',
      type: NotificationType.friendRequest,
      senderId: senderId,
      relatedId: senderId,
    );
  }

  // Friend accepted notification
  factory NotificationModel.friendAccepted({
    required String userId,
    required String senderId,
    required String senderName,
  }) {
    return NotificationModel.create(
      userId: userId,
      title: 'Friend Request Accepted',
      body: '$senderName accepted your friend request',
      type: NotificationType.friendAccepted,
      senderId: senderId,
      relatedId: senderId,
    );
  }

  // Join request notification
  factory NotificationModel.joinRequest({
    required String userId,
    required String senderId,
    required String senderName,
    required String eventId,
    required String eventTitle,
  }) {
    return NotificationModel.create(
      userId: userId,
      title: 'Join Request',
      body: '$senderName wants to join your event: $eventTitle',
      type: NotificationType.joinRequest,
      senderId: senderId,
      relatedId: eventId,
    );
  }

  // Join approved notification
  factory NotificationModel.joinApproved({
    required String userId,
    required String hostId,
    required String hostName,
    required String eventId,
    required String eventTitle,
  }) {
    return NotificationModel.create(
      userId: userId,
      title: 'Join Request Approved',
      body: '$hostName approved your request to join: $eventTitle',
      type: NotificationType.joinApproved,
      senderId: hostId,
      relatedId: eventId,
    );
  }

  // Join rejected notification
  factory NotificationModel.joinRejected({
    required String userId,
    required String hostId,
    required String hostName,
    required String eventId,
    required String eventTitle,
  }) {
    return NotificationModel.create(
      userId: userId,
      title: 'Join Request Rejected',
      body: '$hostName declined your request to join: $eventTitle',
      type: NotificationType.joinRejected,
      senderId: hostId,
      relatedId: eventId,
    );
  }

  // Message notification
  factory NotificationModel.message({
    required String userId,
    required String senderId,
    required String senderName,
    required String chatId,
    required String messagePreview,
    required bool isDirectMessage,
  }) {
    return NotificationModel.create(
      userId: userId,
      title: isDirectMessage ? 'New Message' : 'New Event Message',
      body: '$senderName: $messagePreview',
      type: NotificationType.message,
      senderId: senderId,
      relatedId: chatId,
    );
  }

  // Event reminder notification
  factory NotificationModel.eventReminder({
    required String userId,
    required String eventId,
    required String eventTitle,
    required DateTime eventDateTime,
  }) {
    return NotificationModel.create(
      userId: userId,
      title: 'Event Reminder',
      body: '$eventTitle starts in 1 hour',
      type: NotificationType.eventReminder,
      relatedId: eventId,
    );
  }

  // Convert to JSON for Appwrite
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.toString().split('.').last, // Store enum as string
      'senderId': senderId,
      'relatedId': relatedId,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  // Create from JSON from Appwrite
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    NotificationType type;
    switch (json['type']) {
      case 'friendRequest':
        type = NotificationType.friendRequest;
        break;
      case 'friendAccepted':
        type = NotificationType.friendAccepted;
        break;
      case 'joinRequest':
        type = NotificationType.joinRequest;
        break;
      case 'joinApproved':
        type = NotificationType.joinApproved;
        break;
      case 'joinRejected':
        type = NotificationType.joinRejected;
        break;
      case 'message':
        type = NotificationType.message;
        break;
      case 'eventReminder':
        type = NotificationType.eventReminder;
        break;
      case 'systemMessage':
      default:
        type = NotificationType.systemMessage;
    }

    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: type,
      senderId: json['senderId'] as String?,
      relatedId: json['relatedId'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  // Mark as read
  NotificationModel markAsRead() {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      senderId: senderId,
      relatedId: relatedId,
      timestamp: timestamp,
      isRead: true,
    );
  }
}