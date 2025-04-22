// Update to lib/features/chat/repositories/chat_repository.dart

import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../data/models/chat_model.dart';
import '../data/models/direct_message_model.dart';


// Provider for the chat repository
final chatRepositoryProvider = Provider((ref) {
  return ChatRepository(
    db: Databases(
      Client()
        ..setEndpoint(AppwriteConstants.endpoint)
        ..setProject(AppwriteConstants.projectId),
    ),
    storage: Storage(
      Client()
        ..setEndpoint(AppwriteConstants.endpoint)
        ..setProject(AppwriteConstants.projectId),
    ),
  );
});

class ChatRepository {
  final Databases _db;
  final Storage _storage;

  ChatRepository({
    required Databases db,
    required Storage storage,
  })  : _db = db,
        _storage = storage;

  // DIRECT MESSAGE METHODS

  // Create a new direct message chat
  Future<DirectMessageChat> createDirectChat(DirectMessageChat chat) async {
    try {
      final response = await _db.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId:  AppwriteConstants.directChatCollection, // Add this to your constants
        documentId: chat.chatId,
        data: chat.toJson(),
      );

      return DirectMessageChat.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // Get all direct chats for a user
  Future<List<DirectMessageChat>> getUserDirectChats(String userId) async {
    try {
      final response = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.directChatCollection, // Add this to your constants
        queries: [
          Query.search('participants', userId),
        ],
      );

      return response.documents
          .map((doc) => DirectMessageChat.fromJson(doc.data))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get a specific direct chat
  Future<DirectMessageChat?> getDirectChat(String chatId) async {
    try {
      final response = await _db.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId:  AppwriteConstants.directChatCollection, // Add this to your constants
        documentId: chatId,
      );

      return DirectMessageChat.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  // Get or create a direct chat between two users
  Future<DirectMessageChat> getOrCreateDirectChat(String userId1, String userId2) async {
    try {
      // Try to find existing chat
      final response = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId:  AppwriteConstants.directChatCollection, // Add this to your constants
        queries: [
          Query.search('participants', userId1),
          Query.search('participants', userId2),
        ],
      );

      if (response.documents.isNotEmpty) {
        return DirectMessageChat.fromJson(response.documents.first.data);
      }

      // Create new chat if none exists
      final newChat = DirectMessageChat.create(
        user1Id: userId1,
        user2Id: userId2,
        initialMessage: '',
        senderId: userId1,
      );

      return await createDirectChat(newChat);
    } catch (e) {
      rethrow;
    }
  }

  // Update direct chat with last message
  Future<void> updateDirectChatLastMessage(
      String chatId,
      String message,
      String senderId,
      ) async {
    try {
      await _db.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId:  AppwriteConstants.directChatCollection, // Add this to your constants
        documentId: chatId,
        data: {
          'lastMessage': message,
          'lastSenderId': senderId,
          'lastMessageTime': DateTime.now().toIso8601String(),
          'hasUnread': true,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // Mark direct chat as read
  Future<void> markDirectChatAsRead(String chatId) async {
    try {
      await _db.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId:  AppwriteConstants.directChatCollection, // Add this to your constants
        documentId: chatId,
        data: {
          'hasUnread': false,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // EVENT CHAT METHODS (existing methods)

  // Send a new message
  Future<ChatMessage> sendMessage(ChatMessage message) async {
    try {
      final response = await _db.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.chatMessagesCollection,
        documentId: message.id,
        data: message.toJson(),
      );

      return ChatMessage.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // Upload an image and send it as a message for event chat
  Future<ChatMessage> sendImageMessage({
    required String eventId,
    required String senderId,
    required String senderName,
    required String senderImage,
    required File imageFile,
  }) async {
    try {
      // 1. Upload the image to storage
      final uploadedFile = await _storage.createFile(
        bucketId: AppwriteConstants.chatImagesBucket,
        fileId: ID.unique(),
        file: InputFile.fromPath(
          path: imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      );

      // 2. Get the image URL
      final imageUrl = '${AppwriteConstants.endpoint}/storage/buckets/${AppwriteConstants.chatImagesBucket}/files/${uploadedFile.$id}/preview?project=${AppwriteConstants.projectId}';

      // 3. Create the chat message with the image
      final message = ChatMessage.createImage(
        eventId: eventId,
        senderId: senderId,
        senderName: senderName,
        senderImage: senderImage,
        imageUrl: imageUrl,
      );

      // 4. Save the message to the database
      return await sendMessage(message);
    } catch (e) {
      if (kDebugMode) {
        print('Error in sendImageMessage: $e');
      }
      rethrow;
    }
  }

  // Upload an image and send it as a message for direct chat
  Future<ChatMessage> sendDirectImageMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderImage,
    required File imageFile,
  }) async {
    try {
      // 1. Upload the image to storage
      final uploadedFile = await _storage.createFile(
        bucketId: AppwriteConstants.chatImagesBucket,
        fileId: ID.unique(),
        file: InputFile.fromPath(
          path: imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      );

      // 2. Get the image URL
      final imageUrl = '${AppwriteConstants.endpoint}/storage/buckets/${AppwriteConstants.chatImagesBucket}/files/${uploadedFile.$id}/preview?project=${AppwriteConstants.projectId}';

      // 3. Create the chat message with the image
      final message = ChatMessage.createDirectImageMessage(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderImage: senderImage,
        imageUrl: imageUrl,
      );

      // 4. Save the message to the database
      return await sendMessage(message);
    } catch (e) {
      if (kDebugMode) {
        print('Error in sendDirectImageMessage: $e');
      }
      rethrow;
    }
  }

  // Get all messages for an event
  Future<List<ChatMessage>> getEventMessages(String eventId) async {
    try {
      final response = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.chatMessagesCollection,
        queries: [
          Query.equal('eventId', eventId),
          Query.orderDesc('timestamp'),
        ],
      );

      return response.documents
          .map((doc) => ChatMessage.fromJson(doc.data))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get all messages for a direct chat
  Future<List<ChatMessage>> getDirectChatMessages(String chatId) async {
    try {
      final response = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.chatMessagesCollection,
        queries: [
          Query.equal('chatId', chatId),
          Query.orderDesc('timestamp'),
        ],
      );

      return response.documents
          .map((doc) => ChatMessage.fromJson(doc.data))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Mark a message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _db.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.chatMessagesCollection,
        documentId: messageId,
        data: {'isRead': true},
      );
    } catch (e) {
      rethrow;
    }
  }

  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _db.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.chatMessagesCollection,
        documentId: messageId,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get unread message count for a user
  Future<int> getUnreadMessageCount(String userId, String eventId) async {
    try {
      final response = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.chatMessagesCollection,
        queries: [
          Query.equal('eventId', eventId),
          Query.notEqual('senderId', userId),
          Query.equal('isRead', false),
        ],
      );

      return response.documents.length;
    } catch (e) {
      rethrow;
    }
  }

  // Get all unread direct message chats for a user
  Future<int> getTotalUnreadDirectChats(String userId) async {
    try {
      final response = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: 'AppConstants.directChatCollection', // Add this to your constants
        queries: [
          Query.search('participants', userId),
          Query.equal('hasUnread', true),
          Query.notEqual('lastSenderId', userId),
        ],
      );

      return response.documents.length;
    } catch (e) {
      return 0;
    }
  }
}