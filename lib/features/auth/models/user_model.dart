import 'dart:convert';
import '../../../domain/entities/point.dart';

class UserModel {
  String id;
  String email;
  String name;
  String bio;
  String gender;
  String phone;
  String coverPhoto;
  List<String> userImages;
  List<String> profileImages;
  bool profileComplete;
  double latitude; // Changed from Point to simple double
  double longitude; // Changed from Point to simple double
  List<String> eventsHosted;
  List<String> eventsAttended;
  List<String> friendsList;
  String lookingFor;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.gender,
    required this.phone,
    required this.userImages,
    required this.profileImages,
    required this.bio,
    required this.coverPhoto,
    required this.profileComplete,
    required this.latitude, // Changed
    required this.longitude, // Changed
    required this.eventsHosted,
    required this.eventsAttended,
    required this.friendsList,
    this.lookingFor = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Utility function to parse string lists
    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) return List<String>.from(value);
      if (value is String) {
        try {
          return List<String>.from(jsonDecode(value));
        } catch (_) {
          return [];
        }
      }
      return [];
    }

    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      userImages: parseStringList(
        json['user_images'] ?? json['userImages'] ?? [],
      ),
      profileImages: parseStringList(
        json['profile_images'] ?? json['profileImages'] ?? [],
      ),
      bio: json['bio'] as String? ?? '',
      coverPhoto: json['cover_photo'] ?? json['coverPhoto'] ?? '',
      profileComplete:
          json['profile_complete'] ?? json['profileComplete'] ?? false,
      latitude: (json['latitude'] ?? 0).toDouble(), // Simplified
      longitude: (json['longitude'] ?? 0).toDouble(), // Simplified
      eventsHosted: parseStringList(
        json['events_hosted'] ?? json['eventsHosted'] ?? [],
      ),
      eventsAttended: parseStringList(
        json['events_attended'] ?? json['eventsAttended'] ?? [],
      ),
      friendsList: parseStringList(
        json['friends_list'] ?? json['friendsList'] ?? [],
      ),
      lookingFor: json['looking_for'] ?? json['lookingFor'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'bio': bio,
      'gender': gender,
      'phone': phone,
      'user_images': userImages,
      'profile_images': profileImages,
      'cover_photo': coverPhoto,
      'profile_complete': profileComplete,
      'latitude': latitude, // Simplified
      'longitude': longitude, // Simplified
      'events_hosted': eventsHosted,
      'events_attended': eventsAttended,
      'friends_list': friendsList,
      'looking_for': lookingFor,
    };
  }

  // Helper method to get location as Point object
  Point get location => Point(latitude: latitude, longitude: longitude);

  // Helper method to set location from Point object
  void setLocation(Point point) {
    latitude = point.latitude;
    longitude = point.longitude;
  }

  UserModel copyWith({
    String? email,
    String? name,
    String? bio,
    String? gender,
    String? phone,
    List<String>? userImages,
    List<String>? profileImages,
    String? coverPhoto,
    Point? location,
    double? latitude,
    double? longitude,
    String? lookingFor,
    bool? profileComplete,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      userImages: userImages ?? this.userImages,
      profileImages: profileImages ?? this.profileImages,
      bio: bio ?? this.bio,
      coverPhoto: coverPhoto ?? this.coverPhoto,
      profileComplete: profileComplete ?? this.profileComplete,
      latitude: latitude ?? (location?.latitude ?? this.latitude),
      longitude: longitude ?? (location?.longitude ?? this.longitude),
      eventsHosted: eventsHosted,
      eventsAttended: eventsAttended,
      friendsList: friendsList,
      lookingFor: lookingFor ?? this.lookingFor,
    );
  }
}
