import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/models/comment_model.dart';
import '../repositories/comment_repository.dart';

// Provider for all comments for a specific event
final eventCommentsProvider = StateNotifierProvider.family<CommentController, AsyncValue<List<Comment>>, String>(
      (ref, eventId) {
    final commentRepository = ref.watch(commentRepositoryProvider);
    return CommentController(commentRepository, eventId);
  },
);

class CommentController extends StateNotifier<AsyncValue<List<Comment>>> {
  final CommentRepository _commentRepository;
  final String _eventId;

  CommentController(this._commentRepository, this._eventId) : super(const AsyncValue.loading()) {
    getComments();
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

  Future<void> addComment(Comment comment) async {
    try {
      await _commentRepository.addComment(comment);
      getComments(); // Refresh comments list
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _commentRepository.deleteComment(commentId);
      getComments(); // Refresh comments list
    } catch (e) {
      rethrow;
    }
  }
}