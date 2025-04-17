// Update this file at domain/entities/point.dart

class Point {
  final double latitude;
  final double longitude;

  Point({required this.latitude, required this.longitude});

  // Simple conversion to map
  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude};
  }

  // Create from map
  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }
}
