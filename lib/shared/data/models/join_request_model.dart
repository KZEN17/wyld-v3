import 'package:uuid/uuid.dart';

class JoinRequest {
  String eventId;
  String hostId;
  String requestId;
  String status;
  String userId;

  JoinRequest({
    required this.eventId,
    required this.hostId,
    required this.requestId,
    required this.status,
    required this.userId,
  });

  // Converts a JoinRequest object into a Map
  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'hostId': hostId,
      'requestId': requestId,
      'status': status,
      'userId': userId,
    };
  }

  // Converts a Map into a JoinRequest object
  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    return JoinRequest(
      eventId: json['eventId'] ?? '',
      hostId: json['hostId'] ?? '',
      requestId: json['requestId'] ?? '',
      status: json['status'] ?? '',
      userId: json['userId'] ?? '',
    );
  }

  // A method to create a new JoinRequest with a unique requestId
  static JoinRequest create({
    required String eventId,
    required String hostId,
    required String status,
    required String userId,
  }) {
    String requestId =
        const Uuid().v4(); // Generates a new UUID for the requestId
    return JoinRequest(
      eventId: eventId,
      hostId: hostId,
      requestId: requestId,
      status: status,
      userId: userId,
    );
  }

  // Method to update the status of the join request
  void updateStatus(String newStatus) {
    status = newStatus;
  }
}
