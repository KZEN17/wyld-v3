import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/profile_avatar_widget.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/direct_chat_controller.dart';
import '../data/models/chat_model.dart';
import '../data/models/direct_message_model.dart';

class DirectChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String otherUserId;

  const DirectChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
  });

  @override
  ConsumerState<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends ConsumerState<DirectChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otherUserAsync = ref.watch(userByIdProvider(widget.otherUserId));
    final chatMessagesAsync = ref.watch(directChatMessagesProvider(widget.chatId));
    final authState = ref.watch(authControllerProvider);

    // Loading states for user and auth data
    if (authState.isLoading || otherUserAsync.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.primaryBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Error states
    if (authState.hasError || otherUserAsync.hasError) {
      return Scaffold(
        backgroundColor: AppColors.primaryBackground,
        body: Center(
          child: Text(
            'Error loading data: ${authState.hasError ? authState.error : otherUserAsync.error}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    // Get user data
    final currentUser = authState.value;
    final otherUser = otherUserAsync.value;

    if (currentUser == null || otherUser == null) {
      return const Scaffold(
        backgroundColor: AppColors.primaryBackground,
        body: Center(
          child: Text(
            'User data not available',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: _buildAppBar(context, otherUser.name),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: chatMessagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return _buildEmptyChat();
                }
                return _buildChatList(messages, currentUser.id);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Error loading messages: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),

          // Message input
          _buildMessageInput(currentUser),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, String userName) {
    return AppBar(
      backgroundColor: AppColors.primaryBackground,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.primaryWhite),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          ProfileAvatar(
            userId: widget.otherUserId,
            radius: 18,
            showOnlineIndicator: true,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: const TextStyle(
                  color: AppColors.primaryWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Text(
                "Online", // This could be dynamic based on user status
                style: TextStyle(
                  color: AppColors.secondaryWhite,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: AppColors.primaryWhite),
          onPressed: () {
            _showOptionsBottomSheet(context);
          },
        ),
      ],
    );
  }

  void _showOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: AppColors.primaryWhite),
              title: const Text('View Profile', style: TextStyle(color: AppColors.primaryWhite)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/user-profile-view',
                  arguments: widget.otherUserId,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Block User', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                // Implement block user functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.orange),
              title: const Text('Report Conversation', style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.pop(context);
                // Implement report functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            color: AppColors.secondaryWhite,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No messages yet',
            style: TextStyle(
              color: AppColors.primaryWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Send a message to start the conversation!',
            style: TextStyle(
              color: AppColors.secondaryWhite,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(List<ChatMessage> messages, String currentUserId) {
    // Mark unread messages as read
    for (var message in messages) {
      if (!message.isRead && message.senderId != currentUserId) {
        ref.read(directChatMessagesProvider(widget.chatId).notifier).markAsRead(message.id);
      }
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true, // Display most recent messages at the bottom
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == currentUserId;

        // Determine if we need to show a date header
        final showDateHeader = index == messages.length - 1 ||
            !_isSameDay(messages[index].timestamp, messages[index + 1].timestamp);

        return Column(
          children: [
            if (showDateHeader) _buildDateHeader(message.timestamp),
            _buildMessageBubble(message, isMe),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime timestamp) {
    final today = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    String headerText;
    if (_isSameDay(timestamp, today)) {
      headerText = 'Today';
    } else if (_isSameDay(timestamp, yesterday)) {
      headerText = 'Yesterday';
    } else {
      headerText = DateFormat('MMMM d, yyyy').format(timestamp);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            headerText,
            style: const TextStyle(
              color: AppColors.secondaryWhite,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Message content
            Container(
              padding: message.type == MessageType.text
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                  : const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primaryPink : AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildMessageContent(message),
            ),

            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                DateFormat('h:mm a').format(message.timestamp),
                style: const TextStyle(
                  color: AppColors.secondaryWhite,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: message.senderId == ref.read(authControllerProvider).value?.id
                ? Colors.white
                : AppColors.primaryWhite,
            fontSize: 16,
          ),
        );
      case MessageType.image:
        return GestureDetector(
          onTap: () {
            // Show full screen image view
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenImageView(imageUrl: message.content),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              message.content,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 200,
                  height: 200,
                  color: AppColors.grayBorder,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 200,
                  color: AppColors.grayBorder,
                  child: const Center(
                    child: Icon(Icons.error, color: Colors.red),
                  ),
                );
              },
            ),
          ),
        );
    }
  }

  Widget _buildMessageInput(dynamic user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        border: Border(
          top: BorderSide(color: AppColors.grayBorder, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Image picker button
          IconButton(
            icon: const Icon(Icons.photo, color: AppColors.primaryWhite),
            onPressed: _isUploading ? null : _pickImage,
          ),

          // Text input field
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: AppColors.primaryWhite),
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: AppColors.secondaryWhite),
                border: InputBorder.none,
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: _isUploading ? null : (_) => _sendTextMessage(),
            ),
          ),

          // Send button
          _isUploading
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : IconButton(
            icon: const Icon(Icons.send, color: AppColors.primaryPink),
            onPressed: _sendTextMessage,
          ),
        ],
      ),
    );
  }

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isUploading) return;

    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    try {
      _messageController.clear();

      await ref.read(directChatMessagesProvider(widget.chatId).notifier).sendDirectMessage(
        senderId: user.id,
        senderName: user.name,
        senderImage: user.profileImages.isNotEmpty ? user.profileImages[0] : '',
        text: text,
      );

      // Scroll to bottom
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    if (_isUploading) return;

    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      await ref.read(directChatMessagesProvider(widget.chatId).notifier).sendDirectImageMessage(
        senderId: user.id,
        senderName: user.name,
        senderImage: user.profileImages.isNotEmpty ? user.profileImages[0] : '',
        imageFile: File(image.path),
      );

      // Scroll to bottom
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending image: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    // Add a small delay to ensure the list has updated
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

// Full screen image view
class FullScreenImageView extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageView({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 3.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading image: $error',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}