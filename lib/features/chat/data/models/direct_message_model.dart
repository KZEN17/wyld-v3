// New file: lib/features/chat/data/models/direct_message_model.dart

import 'package:uuid/uuid.dart';

enum ChatType {
  direct,
  event,
}

class DirectMessageChat {
  final String chatId;
  final List<String> participants; // User IDs of participants (2 for direct messages)
  final DateTime lastMessageTime;
  final String lastMessage;
  final String lastSenderId;
  final bool hasUnread; // Whether there are unread messages
  final ChatType chatType;

  DirectMessageChat({
    required this.chatId,
    required this.participants,
    required this.lastMessageTime,
    required this.lastMessage,
    required this.lastSenderId,
    required this.hasUnread,
    this.chatType = ChatType.direct,
  });

  // Create a new direct message chat
  static DirectMessageChat create({
    required String user1Id,
    required String user2Id,
    String initialMessage = '',
    required String senderId,
  }) {
    return DirectMessageChat(
      chatId: const Uuid().v4(),
      participants: [user1Id, user2Id],
      lastMessageTime: DateTime.now(),
      lastMessage: initialMessage,
      lastSenderId: senderId,
      hasUnread: true,
    );
  }

  // Convert to JSON for Appwrite
  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'participants': participants,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'lastMessage': lastMessage,
      'lastSenderId': lastSenderId,
      'hasUnread': hasUnread,
      'chatType': chatType.toString().split('.').last,
    };
  }

  // Create from JSON from Appwrite
  factory DirectMessageChat.fromJson(Map<String, dynamic> json) {
    return DirectMessageChat(
      chatId: json['chatId'] as String,
      participants: List<String>.from(json['participants']),
      lastMessageTime: DateTime.parse(json['lastMessageTime'] as String),
      lastMessage: json['lastMessage'] as String,
      lastSenderId: json['lastSenderId'] as String,
      hasUnread: json['hasUnread'] as bool? ?? false,
      chatType: json['chatType'] == 'event' ? ChatType.event : ChatType.direct,
    );
  }

  // Update last message info
  DirectMessageChat updateLastMessage({
    required String message,
    required String senderId,
  }) {
    return DirectMessageChat(
      chatId: chatId,
      participants: participants,
      lastMessageTime: DateTime.now(),
      lastMessage: message,
      lastSenderId: senderId,
      hasUnread: true,
      chatType: chatType,
    );
  }

  // Mark as read
  DirectMessageChat markAsRead() {
    return DirectMessageChat(
      chatId: chatId,
      participants: participants,
      lastMessageTime: lastMessageTime,
      lastMessage: lastMessage,
      lastSenderId: lastSenderId,
      hasUnread: false,
      chatType: chatType,
    );
  }
}