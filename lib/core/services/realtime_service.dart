import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  return RealtimeService();
});

class RealtimeService {
  final Realtime _realtime;

  RealtimeService()
      : _realtime = Realtime(
    Client()
      ..setEndpoint(AppwriteConstants.endpoint)
      ..setProject(AppwriteConstants.projectId)
      ..setSelfSigned(status: true),
  );

  // Subscribe to changes in any collection
  Stream<RealtimeMessage> subscribeToCollection(String collectionId) {
    return _realtime.subscribe([
      'databases.${AppwriteConstants.databaseId}.collections.$collectionId.documents'
    ]).stream;
  }

  // Subscribe to changes in a specific document
  Stream<RealtimeMessage> subscribeToDocument(String collectionId, String documentId) {
    return _realtime.subscribe([
      'databases.${AppwriteConstants.databaseId}.collections.$collectionId.documents.$documentId'
    ]).stream;
  }

  // Subscribe to any events involving a specific user
  Stream<RealtimeMessage> subscribeToUserEvents(String userId, String collectionId) {
    return _realtime.subscribe([
      'databases.${AppwriteConstants.databaseId}.collections.$collectionId.documents',
    ]).stream.where((event) {
      if (event.payload.containsKey('userId')) {
        return event.payload['userId'] == userId;
      }
      return false;
    });
  }


}