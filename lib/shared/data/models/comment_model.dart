import 'package:uuid/uuid.dart';

class Comment {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String userImage;
  final String text;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.text,
    required this.timestamp,
  });

  // Factory method to create a new comment with a unique ID
  factory Comment.create({
    required String eventId,
    required String userId,
    required String userName,
    required String userImage,
    required String text,
  }) {
    return Comment(
      id: const Uuid().v4(),
      eventId: eventId,
      userId: userId,
      userName: userName,
      userImage: userImage,
      text: text,
      timestamp: DateTime.now(),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Create from JSON
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      eventId: json['eventId'],
      userId: json['userId'],
      userName: json['userName'],
      userImage: json['userImage'],
      text: json['text'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}