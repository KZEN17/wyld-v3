// New file: lib/features/chat/controllers/direct_chat_controller.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/realtime_service.dart';
import '../data/models/chat_model.dart';
import '../data/models/direct_message_model.dart';
import '../repositories/chat_repository.dart';

// Provider for all direct chats of the current user
final userDirectChatsProvider = StateNotifierProvider<DirectChatsController, AsyncValue<List<DirectMessageChat>>>((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  final realtimeService = ref.watch(realtimeServiceProvider);
  return DirectChatsController(chatRepository, realtimeService);
});

// Provider for a specific direct chat with real-time updates
final directChatMessagesProvider = StateNotifierProvider.family<DirectChatMessagesController, AsyncValue<List<ChatMessage>>, String>((ref, chatId) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  final realtimeService = ref.watch(realtimeServiceProvider);
  return DirectChatMessagesController(chatRepository, realtimeService, chatId);
});

// Provider to get or create a direct chat between two users
final getOrCreateDirectChatProvider = FutureProvider.family<DirectMessageChat, (String, String)>((ref, params) {
  final user1Id = params.$1;
  final user2Id = params.$2;
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.getOrCreateDirectChat(user1Id, user2Id);
});

// Provider for total unread direct messages
final unreadDirectChatsCountProvider = FutureProvider.family<int, String>((ref, userId) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return chatRepository.getTotalUnreadDirectChats(userId);
});

// Controller for all direct chats
class DirectChatsController extends StateNotifier<AsyncValue<List<DirectMessageChat>>> {
  final ChatRepository _chatRepository;
  final RealtimeService _realtimeService;
  StreamSubscription? _subscription;
  String? _currentUserId;

  DirectChatsController(this._chatRepository, this._realtimeService)
      : super(const AsyncValue.loading());

  // Initialize with user ID
  void initialize(String userId) {
    _currentUserId = userId;
    getUserChats(userId);
    _subscribeToDirectChats();
  }

  // Get all direct chats for a user
  Future<void> getUserChats(String userId) async {
    state = const AsyncValue.loading();
    try {
      final chats = await _chatRepository.getUserDirectChats(userId);

      // Sort by last message time (most recent first)
      chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

      state = AsyncValue.data(chats);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Subscribe to real-time updates for direct chats
  void _subscribeToDirectChats() {
    try {
      _subscription = _realtimeService
          .subscribeToCollection('direct_chats') // Add this to your constants
          .listen((event) {
        if (_currentUserId == null) return;

        // Check if this chat involves current user
        final participants = event.payload['participants'] as List<dynamic>?;
        if (participants == null || !participants.contains(_currentUserId)) return;

        if (kDebugMode) {
          print('Direct chat update received');
        }

        // Refresh the chats
        getUserChats(_currentUserId!);
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to direct chats: $e');
      }
    }
  }

  // Create a new direct chat
  Future<DirectMessageChat> createDirectChat(String user1Id, String user2Id) async {
    try {
      final chat = DirectMessageChat.create(
        user1Id: user1Id,
        user2Id: user2Id,
        initialMessage: '',
        senderId: user1Id,
      );

      final createdChat = await _chatRepository.createDirectChat(chat);

      // Refresh chats list
      if (_currentUserId != null) {
        getUserChats(_currentUserId!);
      }

      return createdChat;
    } catch (e) {
      rethrow;
    }
  }

  // Mark a direct chat as read
  Future<void> markChatAsRead(String chatId) async {
    try {
      await _chatRepository.markDirectChatAsRead(chatId);

      // Refresh chats list
      if (_currentUserId != null) {
        getUserChats(_currentUserId!);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

// Controller for messages in a specific direct chat
class DirectChatMessagesController extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final ChatRepository _chatRepository;
  final RealtimeService _realtimeService;
  final String _chatId;
  StreamSubscription? _subscription;

  DirectChatMessagesController(this._chatRepository, this._realtimeService, this._chatId)
      : super(const AsyncValue.loading()) {
    getMessages();
    _subscribeToChatMessages();
  }

  // Get all messages for the direct chat
  Future<void> getMessages() async {
    state = const AsyncValue.loading();
    try {
      final messages = await _chatRepository.getDirectChatMessages(_chatId);
      state = AsyncValue.data(messages);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Subscribe to real-time message updates
  void _subscribeToChatMessages() {
    try {
      _subscription = _realtimeService
          .subscribeToCollection(AppwriteConstants.chatMessagesCollection)
          .listen((event) {
        // Handle only messages for this direct chat
        if (event.payload['chatId'] == _chatId) {
          if (kDebugMode) {
            print('Direct chat message update received for chat: $_chatId');
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
        print('Error subscribing to direct chat messages: $e');
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

  // Handle updated message events
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
  Future<void> sendDirectMessage({
    required String senderId,
    required String senderName,
    required String senderImage,
    required String text,
  }) async {
    try {
      if (text.trim().isEmpty) return;

      // Create and send the message
      final message = ChatMessage.createDirectMessage(
        chatId: _chatId,
        senderId: senderId,
        senderName: senderName,
        senderImage: senderImage,
        text: text,
      );

      await _chatRepository.sendMessage(message);

      // Update the direct chat with the last message info
      await _chatRepository.updateDirectChatLastMessage(
        _chatId,
        text,
        senderId,
      );

      // No need to update state manually - we'll get the update via Realtime
    } catch (e) {
      if (kDebugMode) {
        print('Error sending direct message: $e');
      }
      rethrow;
    }
  }

  // Send an image message
  Future<void> sendDirectImageMessage({
    required String senderId,
    required String senderName,
    required String senderImage,
    required File imageFile,
  }) async {
    try {
      // Upload and send the image
      final message = await _chatRepository.sendDirectImageMessage(
        chatId: _chatId,
        senderId: senderId,
        senderName: senderName,
        senderImage: senderImage,
        imageFile: imageFile,
      );

      // Update the direct chat with the last message info
      await _chatRepository.updateDirectChatLastMessage(
        _chatId,
        "📷 Image",
        senderId,
      );

      // No need to update state manually - we'll get the update via Realtime
    } catch (e) {
      if (kDebugMode) {
        print('Error sending direct image message: $e');
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