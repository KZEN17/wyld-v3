import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/data/models/comment_model.dart';

final commentRepositoryProvider = Provider((ref) {
  return CommentRepository(
    db: Databases(
      Client()
        ..setEndpoint(AppwriteConstants.endpoint)
        ..setProject(AppwriteConstants.projectId),
    ),
  );
});

class CommentRepository {
  final Databases _db;

  CommentRepository({required Databases db}) : _db = db;

  // Add a new comment
  Future<Comment> addComment(Comment comment) async {
    try {
      final response = await _db.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.commentsCollection,
        documentId: comment.id,
        data: comment.toJson(),
      );

      return Comment.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  // Get all comments for a specific event
  Future<List<Comment>> getEventComments(String eventId) async {
    try {
      final documents = await _db.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.commentsCollection,
        queries: [
          Query.equal('eventId', eventId),
          Query.orderDesc('timestamp'),
        ],
      );

      return documents.documents
          .map((doc) => Comment.fromJson(doc.data))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Delete a comment
  Future<void> deleteComment(String commentId) async {
    try {
      await _db.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.commentsCollection,
        documentId: commentId,
      );
    } catch (e) {
      rethrow;
    }
  }
}