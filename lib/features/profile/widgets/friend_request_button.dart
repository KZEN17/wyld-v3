import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/friend_controller.dart';

class FriendRequestButton extends ConsumerStatefulWidget {
  final String targetUserId;
  final FriendshipStatus friendshipStatus;

  const FriendRequestButton({
    super.key,
    required this.targetUserId,
    required this.friendshipStatus,
  });

  @override
  ConsumerState<FriendRequestButton> createState() => _FriendRequestButtonState();
}

class _FriendRequestButtonState extends ConsumerState<FriendRequestButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return _buildButton();
  }

  Widget _buildButton() {
    switch (widget.friendshipStatus) {
      case FriendshipStatus.friends:
        return OutlinedButton.icon(
          onPressed: _isLoading ? null : _removeFriend,
          icon: const Icon(Icons.check, size: 16),
          label: const Text('Friends'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryWhite,
            side: const BorderSide(color: AppColors.primaryWhite),
          ),
        );

      case FriendshipStatus.pending_outgoing:
        return OutlinedButton.icon(
          onPressed: _isLoading ? null : _cancelRequest,
          icon: const Icon(Icons.hourglass_empty, size: 16),
          label: const Text('Request Sent'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.secondaryWhite,
            side: const BorderSide(color: AppColors.secondaryWhite),
          ),
        );

      case FriendshipStatus.pending_incoming:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _acceptRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                ),
                child: const Text('Accept'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _declineRequest,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondaryWhite,
                  side: const BorderSide(color: AppColors.secondaryWhite),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                ),
                child: const Text('Decline'),
              ),
            ),
          ],
        );

      case FriendshipStatus.none:
      default:
        return ElevatedButton.icon(
          onPressed: _isLoading ? null : _sendFriendRequest,
          icon: const Icon(Icons.person_add, size: 16),
          label: const Text('Add Friend'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPink,
            foregroundColor: Colors.white,
          ),
        );
    }
  }

  Future<void> _sendFriendRequest() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(friendControllerProvider).sendFriendRequest(widget.targetUserId);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request sent')),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending friend request: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelRequest() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(friendControllerProvider).cancelFriendRequest(widget.targetUserId);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request cancelled')),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling request: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptRequest() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(friendControllerProvider).acceptFriendRequest(widget.targetUserId);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request accepted')),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting request: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _declineRequest() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(friendControllerProvider).declineFriendRequest(widget.targetUserId);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request declined')),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error declining request: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeFriend() async {
    if (_isLoading) return;

    // Show confirmation dialog
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: const Text('Remove Friend', style: TextStyle(color: AppColors.primaryWhite)),
        content: const Text('Are you sure you want to remove this friend?', style: TextStyle(color: AppColors.secondaryWhite)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryWhite)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(friendControllerProvider).removeFriend(widget.targetUserId);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend removed')),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing friend: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}