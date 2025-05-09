// In your AppwriteConstants.dart file
class AppwriteConstants {
  static const String projectId = '67fe4b3f002c42cf918b';
  static const String endpoint = 'http://10.0.2.2/v1';

  static const String databaseId = '67fe52e200036849720e';
  static const String usersCollection = '67fe52fd0006b9949549';
  static const String eventsCollection = '67ffba650028934154e5';
  static const String joinRequestsCollection = '67ffba7e000dc2ab12a6';
  static const String commentsCollection = '6805fd2c0023c9d43b5f';
  static const String chatMessagesCollection = '680660040023de0642e4';
  static const String friendRequestsCollection = '68073665003250f1ccc5';
  static const String directChatCollection = '68073b18002fb1e7b4a9';
  static const String imagesBucket = '67fe5500000d190168e9';
  static const String eventImagesBucket = '67ffba4800250225e31c';
  static const String chatImagesBucket = '68065fdb0024cb79cf59';

  // Generate image preview URL
  static String imagePreviewUrl(String fileId) {
    return '$endpoint/storage/buckets/$imagesBucket/files/$fileId/preview?project=$projectId';
  }

  // Generate file view URL
  static String fileViewUrl(String fileId) {
    return '$endpoint/storage/buckets/$imagesBucket/files/$fileId/view?project=$projectId';
  }

}
