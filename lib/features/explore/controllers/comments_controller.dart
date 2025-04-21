import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/models.dart' as models;

import '../../../core/constants/app_constants.dart';
import '../../../core/services/realtime_service.dart';
import '../../../shared/data/models/comment_model.dart';
import '../repositories/comment_repository.dart';

// Provider for all comments for a specific event with real-time updates
final eventCommentsProvider = StateNotifierProvider.family<CommentController, AsyncValue<List<Comment>>, String>(
      (ref, eventId) {
    final commentRepository = ref.watch(commentRepositoryProvider);
    final realtimeService = ref.watch(realtimeServiceProvider);
    return CommentController(commentRepository, realtimeService, eventId);
  },
);

class CommentController extends StateNotifier<AsyncValue<List<Comment>>> {
  final CommentRepository _commentRepository;
  final RealtimeService _realtimeService;
  final String _eventId;
  StreamSubscription? _subscription;

  CommentController(this._commentRepository, this._realtimeService, this._eventId)
      : super(const AsyncValue.loading()) {
    getComments();
    _subscribeToComments();
  }

  Future<void> getComments() async {
    state = const AsyncValue.loading();
    try {
      final comments = await _commentRepository.getEventComments(_eventId);
      state = AsyncValue.data(comments);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void _subscribeToComments() {
    try {
      _subscription = _realtimeService
          .subscribeToCollection(AppwriteConstants.commentsCollection)
          .listen((event) {
        // Handle only events for this specific event
        if (event.payload['eventId'] == _eventId) {
          if (kDebugMode) {
            print('Comment realtime event: ${event.events} for event: $_eventId');
          }

          // Determine the type of event
          if (event.events.contains('databases.*.collections.*.documents.*.create')) {
            _handleNewComment(event.payload);
          } else if (event.events.contains('databases.*.collections.*.documents.*.delete')) {
            _handleDeletedComment(event.payload);
          } else if (event.events.contains('databases.*.collections.*.documents.*.update')) {
            _handleUpdatedComment(event.payload);
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to comments: $e');
      }
    }
  }

  void _handleNewComment(Map<String, dynamic> payload) {
    if (state.hasValue) {
      final currentComments = state.value!;
      final newComment = Comment.fromJson(payload);

      // Add the new comment at the beginning of the list (most recent first)
      final updatedComments = [newComment, ...currentComments];
      state = AsyncValue.data(updatedComments);
    }
  }

  void _handleDeletedComment(Map<String, dynamic> payload) {
    if (state.hasValue) {
      final currentComments = state.value!;
      final commentId = payload['id'];

      // Filter out the deleted comment
      final updatedComments = currentComments.where((comment) => comment.id != commentId).toList();
      state = AsyncValue.data(updatedComments);
    }
  }

  void _handleUpdatedComment(Map<String, dynamic> payload) {
    if (state.hasValue) {
      final currentComments = state.value!;
      final updatedComment = Comment.fromJson(payload);

      // Replace the updated comment
      final updatedComments = currentComments.map((comment) {
        if (comment.id == updatedComment.id) {
          return updatedComment;
        }
        return comment;
      }).toList();

      state = AsyncValue.data(updatedComments);
    }
  }

  Future<void> addComment(Comment comment) async {
    try {
      await _commentRepository.addComment(comment);
      // No need to call getComments() - we'll get the update via Realtime
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _commentRepository.deleteComment(commentId);
      // No need to call getComments() - we'll get the update via Realtime
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