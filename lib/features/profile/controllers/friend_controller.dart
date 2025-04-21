import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/friend_request_model.dart';
import '../repositories/friend_repository.dart';
import '../../auth/controllers/auth_controller.dart';

// Provider for friend controller
final friendControllerProvider = Provider((ref) {
  final friendRepository = ref.watch(friendRepositoryProvider);
  return FriendController(friendRepository, ref);
});

// Enum to represent friendship status
enum FriendshipStatus {
  none,             // No relationship
  pending_outgoing, // Current user sent a request to the target user
  pending_incoming, // Target user sent a request to the current user
  friends           // Users are friends
}

// Provider for checking friendship status between current user and another user
final friendshipStatusProvider = FutureProvider.family<FriendshipStatus, String>((ref, targetUserId) async {
  final currentUserAsync = ref.watch(authControllerProvider);
  final friendRepository = ref.watch(friendRepositoryProvider);

  // Get current user ID
  final currentUser = currentUserAsync.value;
  if (currentUser == null) return FriendshipStatus.none;

  // First check if they are already friends
  if (currentUser.friendsList.contains(targetUserId)) {
    return FriendshipStatus.friends;
  }

  // Check if there are any pending requests
  final pendingRequests = await friendRepository.getPendingRequests();

  // Check for outgoing request (current user -> target user)
  final outgoingRequest = pendingRequests.where(
          (request) => request.senderId == currentUser.id && request.receiverId == targetUserId
  ).toList();

  if (outgoingRequest.isNotEmpty) {
    return FriendshipStatus.pending_outgoing;
  }

  // Check for incoming request (target user -> current user)
  final incomingRequest = pendingRequests.where(
          (request) => request.senderId == targetUserId && request.receiverId == currentUser.id
  ).toList();

  if (incomingRequest.isNotEmpty) {
    return FriendshipStatus.pending_incoming;
  }

  // No relationship
  return FriendshipStatus.none;
});

// Provider for getting all pending friend requests for the current user
final pendingFriendRequestsProvider = FutureProvider<List<FriendRequest>>((ref) async {
  final currentUserAsync = ref.watch(authControllerProvider);
  final friendRepository = ref.watch(friendRepositoryProvider);

  // Get current user ID
  final currentUser = currentUserAsync.value;
  if (currentUser == null) return [];

  // Get all pending requests
  final pendingRequests = await friendRepository.getPendingRequests();

  // Return only incoming requests (where current user is the receiver)
  return pendingRequests.where(
          (request) => request.receiverId == currentUser.id
  ).toList();
});

// Controller for friend-related operations
class FriendController {
  final FriendRepository _friendRepository;
  final Ref _ref;

  FriendController(this._friendRepository, this._ref);

  // Send a friend request
  Future<void> sendFriendRequest(String targetUserId) async {
    final currentUserAsync = _ref.read(authControllerProvider);
    final currentUser = currentUserAsync.value;

    if (currentUser == null) {
      throw Exception('You must be logged in to send a friend request');
    }

    // Create friend request model
    final request = FriendRequest.create(
      senderId: currentUser.id,
      receiverId: targetUserId,
    );

    // Save to repository
    await _friendRepository.sendFriendRequest(request);

    // Invalidate relevant providers to refresh data
    _ref.invalidate(friendshipStatusProvider(targetUserId));
  }

  // Cancel a sent friend request
  Future<void> cancelFriendRequest(String targetUserId) async {
    final currentUserAsync = _ref.read(authControllerProvider);
    final currentUser = currentUserAsync.value;

    if (currentUser == null) {
      throw Exception('You must be logged in to cancel a friend request');
    }

    // Get pending requests
    final pendingRequests = await _friendRepository.getPendingRequests();

    // Find the specific request
    final requestToCancel = pendingRequests.firstWhere(
          (request) => request.senderId == currentUser.id && request.receiverId == targetUserId,
      orElse: () => throw Exception('Friend request not found'),
    );

    // Delete the request
    await _friendRepository.deleteFriendRequest(requestToCancel.id);

    // Invalidate relevant providers
    _ref.invalidate(friendshipStatusProvider(targetUserId));
  }

  // Accept a friend request
  Future<void> acceptFriendRequest(String senderId) async {
    final currentUserAsync = _ref.read(authControllerProvider);
    final currentUser = currentUserAsync.value;

    if (currentUser == null) {
      throw Exception('You must be logged in to accept a friend request');
    }

    // Get pending requests
    final pendingRequests = await _friendRepository.getPendingRequests();

    // Find the specific request
    final requestToAccept = pendingRequests.firstWhere(
          (request) => request.senderId == senderId && request.receiverId == currentUser.id,
      orElse: () => throw Exception('Friend request not found'),
    );

    // Add both users to each other's friends list
    await _friendRepository.addFriend(currentUser.id, senderId);

    // Delete the request
    await _friendRepository.deleteFriendRequest(requestToAccept.id);

    // Invalidate relevant providers
    _ref.invalidate(friendshipStatusProvider(senderId));
    _ref.invalidate(authControllerProvider);
  }

  // Decline a friend request
  Future<void> declineFriendRequest(String senderId) async {
    final currentUserAsync = _ref.read(authControllerProvider);
    final currentUser = currentUserAsync.value;

    if (currentUser == null) {
      throw Exception('You must be logged in to decline a friend request');
    }

    // Get pending requests
    final pendingRequests = await _friendRepository.getPendingRequests();

    // Find the specific request
    final requestToDecline = pendingRequests.firstWhere(
          (request) => request.senderId == senderId && request.receiverId == currentUser.id,
      orElse: () => throw Exception('Friend request not found'),
    );

    // Delete the request
    await _friendRepository.deleteFriendRequest(requestToDecline.id);

    // Invalidate relevant providers
    _ref.invalidate(friendshipStatusProvider(senderId));
  }

  // Remove a friend
  Future<void> removeFriend(String friendId) async {
    final currentUserAsync = _ref.read(authControllerProvider);
    final currentUser = currentUserAsync.value;

    if (currentUser == null) {
      throw Exception('You must be logged in to remove a friend');
    }

    // Remove from both users' friends lists
    await _friendRepository.removeFriend(currentUser.id, friendId);

    // Invalidate relevant providers
    _ref.invalidate(friendshipStatusProvider(friendId));
    _ref.invalidate(authControllerProvider);
  }}