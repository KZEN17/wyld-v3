import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../models/friend_request_model.dart';
import '../../auth/models/user_model.dart';

// Provider for friend repository
final friendRepositoryProvider = Provider((ref) {
  return FriendRepository(
    db: Databases(
      Client()
        ..setEndpoint(AppwriteConstants.endpoint)
        ..setProject(AppwriteConstants.projectId)
        ..setSelfSigned(status: true),
    ),
  );
});



class FriendRepository {
  final Databases _db;

  FriendRepository({required Databases db}) : _db = db;

  // Send a friend request
  Future<void> sendFriendRequest(FriendRequest request) async {
    try {
      await _db.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.friendRequestsCollection,
        documentId: request.id,
        data: request.toJson(),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get pending friend requests for a user
  Future<List<FriendRequest>> getPendingRequests() async {
    try {
      final response = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.friendRequestsCollection,
      );

      return response.documents
          .map((doc) => FriendRequest.fromJson(doc.data))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Delete a friend request
  Future<void> deleteFriendRequest(String requestId) async {
    try {
      await _db.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.friendRequestsCollection,
        documentId: requestId,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Add users to each other's friend lists
  Future<void> addFriend(String userId1, String userId2) async {
    try {
      // Get both users
      final user1Doc = await _db.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId1,
      );

      final user2Doc = await _db.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId2,
      );

      // Parse into user models
      final user1 = UserModel.fromJson(user1Doc.data);
      final user2 = UserModel.fromJson(user2Doc.data);

      // Add to each other's friends list if not already there
      if (!user1.friendsList.contains(userId2)) {
        user1.friendsList.add(userId2);
      }

      if (!user2.friendsList.contains(userId1)) {
        user2.friendsList.add(userId1);
      }

      // Update both users
      await _db.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId1,
        data: {'friends_list': user1.friendsList},
      );

      await _db.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId2,
        data: {'friends_list': user2.friendsList},
      );
    } catch (e) {
      rethrow;
    }
  }

  // Remove users from each other's friend lists
  Future<void> removeFriend(String userId1, String userId2) async {
    try {
      // Get both users
      final user1Doc = await _db.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId1,
      );

      final user2Doc = await _db.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId2,
      );

      // Parse into user models
      final user1 = UserModel.fromJson(user1Doc.data);
      final user2 = UserModel.fromJson(user2Doc.data);

      // Remove from each other's friends list
      user1.friendsList.remove(userId2);
      user2.friendsList.remove(userId1);

      // Update both users
      await _db.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId1,
        data: {'friends_list': user1.friendsList},
      );

      await _db.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId2,
        data: {'friends_list': user2.friendsList},
      );
    } catch (e) {
      rethrow;
    }
  }
}