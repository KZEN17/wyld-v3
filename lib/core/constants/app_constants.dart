// In your AppwriteConstants.dart file
class AppwriteConstants {
  static const String projectId = '67fe4b3f002c42cf918b';
  static const String endpoint = 'http://10.0.2.2/v1';

  static const String databaseId = '67fe52e200036849720e';
  static const String usersCollection = '67fe52fd0006b9949549';
  static const String eventsCollection = '67ffba650028934154e5';
  static const String joinRequestsCollection = '67ffba7e000dc2ab12a6';
  static const String commentsCollection = '6805fd2c0023c9d43b5f';
  static const String imagesBucket = '67fe5500000d190168e9';
  static const eventImagesBucket = '67ffba4800250225e31c';

  // Generate image preview URL
  static String imagePreviewUrl(String fileId) {
    return '$endpoint/storage/buckets/$imagesBucket/files/$fileId/preview?project=$projectId';
  }

  // Generate file view URL
  static String fileViewUrl(String fileId) {
    return '$endpoint/storage/buckets/$imagesBucket/files/$fileId/view?project=$projectId';
  }
}
