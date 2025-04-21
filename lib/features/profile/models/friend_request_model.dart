import 'package:uuid/uuid.dart';

class FriendRequest {
  String id;
  String senderId;
  String receiverId;
  DateTime timestamp;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.timestamp,
  });

  // Create a new request with a unique ID and current timestamp
  static FriendRequest create({
    required String senderId,
    required String receiverId,
  }) {
    return FriendRequest(
      id: const Uuid().v4(),
      senderId: senderId,
      receiverId: receiverId,
      timestamp: DateTime.now(),
    );
  }

  // Convert to JSON for Appwrite
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Create from JSON from Appwrite
  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}