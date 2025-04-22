// Update to lib/features/chat/data/models/chat_model.dart

import 'package:uuid/uuid.dart';

enum MessageType {
  text,
  image,
}

class ChatMessage {
  final String id;
  final String? eventId; // Optional for event chats
  final String? chatId;  // Optional for direct chats
  final String senderId;
  final String senderName;
  final String senderImage;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    this.eventId,
    this.chatId,
    required this.senderId,
    required this.senderName,
    required this.senderImage,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  // Factory method to create a new text message for an event
  factory ChatMessage.createText({
    required String eventId,
    required String senderId,
    required String senderName,
    required String senderImage,
    required String text,
  }) {
    return ChatMessage(
      id: const Uuid().v4(),
      eventId: eventId,
      senderId: senderId,
      senderName: senderName,
      senderImage: senderImage,
      content: text,
      type: MessageType.text,
      timestamp: DateTime.now(),
    );
  }

  // Factory method to create a new image message for an event
  factory ChatMessage.createImage({
    required String eventId,
    required String senderId,
    required String senderName,
    required String senderImage,
    required String imageUrl,
  }) {
    return ChatMessage(
      id: const Uuid().v4(),
      eventId: eventId,
      senderId: senderId,
      senderName: senderName,
      senderImage: senderImage,
      content: imageUrl,
      type: MessageType.image,
      timestamp: DateTime.now(),
    );
  }

  // Factory method to create a new direct text message
  factory ChatMessage.createDirectMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderImage,
    required String text,
  }) {
    return ChatMessage(
      id: const Uuid().v4(),
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderImage: senderImage,
      content: text,
      type: MessageType.text,
      timestamp: DateTime.now(),
    );
  }

  // Factory method to create a new direct image message
  factory ChatMessage.createDirectImageMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderImage,
    required String imageUrl,
  }) {
    return ChatMessage(
      id: const Uuid().v4(),
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderImage: senderImage,
      content: imageUrl,
      type: MessageType.image,
      timestamp: DateTime.now(),
    );
  }

  // Convert to JSON for Appwrite
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderImage': senderImage,
      'content': content,
      'type': type.toString().split('.').last, // Store enum as string
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };

    // Add optional fields if they exist
    if (eventId != null) data['eventId'] = eventId;
    if (chatId != null) data['chatId'] = chatId;

    return data;
  }

  // Create from JSON from Appwrite
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      eventId: json['eventId'] as String?,
      chatId: json['chatId'] as String?,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderImage: json['senderImage'] as String,
      content: json['content'] as String,
      type: json['type'] == 'image' ? MessageType.image : MessageType.text,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  // Create a copy with some fields updated
  ChatMessage copyWith({
    bool? isRead,
  }) {
    return ChatMessage(
      id: id,
      eventId: eventId,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderImage: senderImage,
      content: content,
      type: type,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}