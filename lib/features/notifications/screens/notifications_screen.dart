import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/notification_controller.dart';
import '../data/models/notification_model.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize notifications for current user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authControllerProvider);
      if (authState.hasValue && authState.value != null) {
        ref.read(userNotificationsProvider.notifier).initialize(authState.value!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final notificationsAsync = ref.watch(userNotificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.primaryWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Mark all notifications as read
              ref.read(userNotificationsProvider.notifier).markAllAsRead();
            },
            child: const Text(
              'Mark All Read',
              style: TextStyle(color: AppColors.primaryPink),
            ),
          ),
        ],
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text(
                'Please log in to view notifications',
                style: TextStyle(color: AppColors.primaryWhite),
              ),
            );
          }

          return notificationsAsync.when(
            data: (notifications) {
              if (notifications.isEmpty) {
                return const Center(
                  child: Text(
                    'No notifications',
                    style: TextStyle(
                      color: AppColors.secondaryWhite,
                      fontSize: 16,
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _buildNotificationItem(notification);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text(
                'Error loading notifications: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Error loading user: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        // TODO: Implement notification deletion
      },
      child: ListTile(
        tileColor: notification.isRead
            ? AppColors.primaryBackground
            : AppColors.secondaryBackground,
        leading: _getNotificationIcon(notification),
        title: Text(
          notification.title,
          style: TextStyle(
            color: AppColors.primaryWhite,
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(
          notification.body,
          style: TextStyle(
            color: AppColors.secondaryWhite,
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        trailing: Text(
          _formatTimestamp(notification.timestamp),
          style: const TextStyle(
            color: AppColors.secondaryWhite,
            fontSize: 12,
          ),
        ),
        onTap: () {
          // Mark as read
          ref.read(userNotificationsProvider.notifier).markAsRead(notification.id);

          // Navigate based on notification type
          _handleNotificationTap(notification);
        },
      ),
    );
  }

  Widget _getNotificationIcon(NotificationModel notification) {
    switch (notification.type) {
      case NotificationType.friendRequest:
        return const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.person_add, color: Colors.white),
        );
      case NotificationType.friendAccepted:
        return const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.people, color: Colors.white),
        );
      case NotificationType.joinRequest:
        return const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.event, color: Colors.white),
        );
      case NotificationType.joinApproved:
      case NotificationType.joinRejected:
        return const CircleAvatar(
          backgroundColor: Colors.purple,
          child: Icon(Icons.event_available, color: Colors.white),
        );
      case NotificationType.message:
        return const CircleAvatar(
          backgroundColor: AppColors.primaryPink,
          child: Icon(Icons.message, color: Colors.white),
        );
      case NotificationType.eventReminder:
        return const CircleAvatar(
          backgroundColor: Colors.teal,
          child: Icon(Icons.notifications, color: Colors.white),
        );
      case NotificationType.systemMessage:
      default:
        return const CircleAvatar(
          backgroundColor: AppColors.secondaryBackground,
          child: Icon(Icons.notifications_none, color: Colors.white),
        );
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    switch (notification.type) {
      case NotificationType.friendRequest:
      case NotificationType.friendAccepted:
      // Navigate to user profile or friend requests
        Navigator.pushNamed(context, '/friend-requests');
        break;
      case NotificationType.joinRequest:
      case NotificationType.joinApproved:
      case NotificationType.joinRejected:
      // Navigate to specific event details
        if (notification.relatedId != null) {
          Navigator.pushNamed(
            context,
            '/chosen-event-details',
            arguments: notification.relatedId,
          );
        }
        break;
      case NotificationType.message:
      // Navigate to chat (direct or event)
        if (notification.relatedId != null) {
          // Check if it's a direct or event message
          Navigator.pushNamed(
            context,
            notification.body.contains('event') ? '/chat' : '/direct-chat',
            arguments: notification.relatedId,
          );
        }
        break;
      case NotificationType.eventReminder:
      // Navigate to event details
        if (notification.relatedId != null) {
          Navigator.pushNamed(
            context,
            '/chosen-event-details',
            arguments: notification.relatedId,
          );
        }
        break;
      case NotificationType.systemMessage:
      default:
      // Maybe show a system message dialog or do nothing
        break;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return DateFormat('MM/dd/yy').format(timestamp);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}