class Announcement {
  final String id;
  final String adminId;
  final String department;
  final String title;
  final String content;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.adminId,
    required this.department,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      adminId: json['admin_id'],
      department: json['department'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin_id': adminId,
      'department': department,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
