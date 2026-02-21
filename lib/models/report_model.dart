class Report {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String? locationAddress;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final String status;
  final DateTime createdAt;
  final String? userName;

  Report({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    this.locationAddress,
    this.latitude,
    this.longitude,
    this.imageUrl,
    required this.status,
    required this.createdAt,
    this.userName,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] ?? 'General', // Default to General if null
      locationAddress: json['location_address'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      imageUrl: json['image_url'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: json['profiles'] != null && (json['profiles'] is Map)
          ? json['profiles']['username'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'location_address': locationAddress,
      'latitude': latitude,
      'longitude': longitude,
      'image_url': imageUrl,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
