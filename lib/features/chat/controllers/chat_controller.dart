// lib/features/chat/controllers/chat_controller.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/realtime_service.dart';
import '../data/models/chat_model.dart';
import '../repositories/chat_repository.dart';

// Provider for event chat messages with real-time updates
final eventChatProvider = StateNotifierProvider.family<ChatController, AsyncValue<List<ChatMessage>>, String>(
      (ref, eventId) {
    final chatRepository = ref.watch(chatRepositoryProvider);
    final realtimeService = ref.watch(realtimeServiceProvider);
    return ChatController(chatRepository, realtimeService, eventId);
  },
);

// Provider for unread message count
final unreadMessageCountProvider = FutureProvider.family<int, Map<String, String>>(
      (ref, params) {
    final userId = params['userId']!;
    final eventId = params['eventId']!;
    final chatRepository = ref.watch(chatRepositoryProvider);
    return chatRepository.getUnreadMessageCount(userId, eventId);
  },
);

class ChatController extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final ChatRepository _chatRepository;
  final RealtimeService _realtimeService;
  final String _eventId;
  StreamSubscription? _subscription;

  ChatController(this._chatRepository, this._realtimeService, this._eventId)
      : super(const AsyncValue.loading()) {
    getMessages();
    _subscribeToChatMessages();
  }

  // Get all messages for the event
  Future<void> getMessages() async {
    state = const AsyncValue.loading();
    try {
      final messages = await _chatRepository.getEventMessages(_eventId);
      state = AsyncValue.data(messages);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Subscribe to real-time chat message updates
  void _subscribeToChatMessages() {
    try {
      _subscription = _realtimeService
          .subscribeToCollection(AppwriteConstants.chatMessagesCollection)
          .listen((event) {
        // Handle only events for this specific event's chat
        if (event.payload['eventId'] == _eventId) {
          if (kDebugMode) {
            print('Chat message realtime event: ${event.events} for event: $_eventId');
          }

          // Determine the type of event
          if (event.events.contains('databases.*.collections.*.documents.*.create')) {
            _handleNewMessage(event.payload);
          } else if (event.events.contains('databases.*.collections.*.documents.*.delete')) {
            _handleDeletedMessage(event.payload);
          } else if (event.events.contains('databases.*.collections.*.documents.*.update')) {
            _handleUpdatedMessage(event.payload);
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to chat messages: $e');
      }
    }
  }

  // Handle new message events
  void _handleNewMessage(Map<String, dynamic> payload) {
    if (state.hasValue) {
      final currentMessages = state.value!;
      final newMessage = ChatMessage.fromJson(payload);

      // Add the new message at the beginning of the list (most recent first)
      final updatedMessages = [newMessage, ...currentMessages];
      state = AsyncValue.data(updatedMessages);
    }
  }

  // Handle deleted message events
  void _handleDeletedMessage(Map<String, dynamic> payload) {
    if (state.hasValue) {
      final currentMessages = state.value!;
      final messageId = payload['id'];

      // Filter out the deleted message
      final updatedMessages = currentMessages.where((message) => message.id != messageId).toList();
      state = AsyncValue.data(updatedMessages);
    }
  }

  // Handle updated message events (e.g., marking as read)
  void _handleUpdatedMessage(Map<String, dynamic> payload) {
    if (state.hasValue) {
      final currentMessages = state.value!;
      final updatedMessage = ChatMessage.fromJson(payload);

      // Replace the updated message
      final updatedMessages = currentMessages.map((message) {
        if (message.id == updatedMessage.id) {
          return updatedMessage;
        }
        return message;
      }).toList();

      state = AsyncValue.data(updatedMessages);
    }
  }

  // Send a text message
  Future<void> sendTextMessage({
    required String senderId,
    required String senderName,
    required String senderImage,
    required String text,
  }) async {
    try {
      if (text.trim().isEmpty) return;

      final message = ChatMessage.createText(
        eventId: _eventId,
        senderId: senderId,
        senderName: senderName,
        senderImage: senderImage,
        text: text,
      );

      await _chatRepository.sendMessage(message);
      // No need to update state manually - we'll get the update via Realtime
    } catch (e) {
      if (kDebugMode) {
        print('Error sending text message: $e');
      }
      rethrow;
    }
  }

  // Send an image message
  Future<void> sendImageMessage({
    required String senderId,
    required String senderName,
    required String senderImage,
    required File imageFile,
  }) async {
    try {
      await _chatRepository.sendImageMessage(
        eventId: _eventId,
        senderId: senderId,
        senderName: senderName,
        senderImage: senderImage,
        imageFile: imageFile,
      );
      // No need to update state manually - we'll get the update via Realtime
    } catch (e) {
      if (kDebugMode) {
        print('Error sending image message: $e');
      }
      rethrow;
    }
  }

  // Mark a message as read
  Future<void> markAsRead(String messageId) async {
    try {
      await _chatRepository.markMessageAsRead(messageId);
      // No need to update state manually - we'll get the update via Realtime
    } catch (e) {
      if (kDebugMode) {
        print('Error marking message as read: $e');
      }
      rethrow;
    }
  }

  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _chatRepository.deleteMessage(messageId);
      // No need to update state manually - we'll get the update via Realtime
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting message: $e');
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}