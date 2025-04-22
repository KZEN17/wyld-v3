import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/data/models/join_request_model.dart';

final joinRequestRepositoryProvider = Provider((ref) {
  return JoinRequestRepository(
    db: Databases(
      Client()
        ..setEndpoint(AppwriteConstants.endpoint)
        ..setProject(AppwriteConstants.projectId),
    ),
  );
});

class JoinRequestRepository {
  final Databases _db;

  JoinRequestRepository({required Databases db}) : _db = db;

  // Create a new join request
  Future<void> sendJoinRequest(
      String eventId,
      String hostId,
      String userId,
      ) async {
    try {
      final joinRequest = JoinRequest.create(
        eventId: eventId,
        hostId: hostId,
        status: 'pending',
        userId: userId,
      );

      await _db.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.joinRequestsCollection,
        documentId: joinRequest.requestId,
        data: joinRequest.toJson(),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Update the status of a join request
  Future<void> updateRequestStatus(String requestId, String newStatus) async {
    try {
      await _db.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.joinRequestsCollection,
        documentId: requestId,
        data: {'status': newStatus},
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get all join requests for a specific event
  Future<List<JoinRequest>> getEventRequests(String eventId) async {
    try {
      final documents = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.joinRequestsCollection,
        queries: [Query.equal('eventId', eventId)],
      );

      return documents.documents
          .map((document) => JoinRequest.fromJson(document.data))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get all pending requests for a host
  Future<List<JoinRequest>> getHostPendingRequests(String hostId) async {
    try {
      final documents = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.joinRequestsCollection,
        queries: [
          Query.equal('hostId', hostId),
          Query.equal('status', 'pending'),
        ],
      );

      return documents.documents
          .map((document) => JoinRequest.fromJson(document.data))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get all requests for a host (regardless of status)
  Future<List<JoinRequest>> getHostAllRequests(String hostId) async {
    try {
      final documents = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.joinRequestsCollection,
        queries: [
          Query.equal('hostId', hostId),
        ],
      );

      return documents.documents
          .map((document) => JoinRequest.fromJson(document.data))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  // Get all requests (used for finding specific request by ID)
  Future<List<JoinRequest>> getAllRequests() async {
    try {
      final documents = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.joinRequestsCollection,
      );

      return documents.documents
          .map((doc) => JoinRequest.fromJson(doc.data))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  // Check if a user has a pending request for an event
  Future<bool> userHasPendingRequest(String userId, String eventId) async {
    try {
      final documents = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.joinRequestsCollection,
        queries: [
          Query.equal('userId', userId),
          Query.equal('eventId', eventId),
          Query.equal('status', 'pending'),
        ],
      );

      return documents.documents.isNotEmpty;
    } catch (e) {
      rethrow;
    }
  }
}