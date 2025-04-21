import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../data/models/chat_model.dart';

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

  // Upload an image and send it as a message
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
}