import 'report_model.dart';

class UserModel {
  final String id;
  final String name;
  final String location;
  final String avatarUrl;
  final int totalReports;
  final int fixedReports;
  final int impactPoints;
  final List<Report> recentSubmissions;

  UserModel({
    required this.id,
    required this.name,
    required this.location,
    required this.avatarUrl,
    required this.totalReports,
    required this.fixedReports,
    required this.impactPoints,
    required this.recentSubmissions,
  });

  factory UserModel.fromJson(
    Map<String, dynamic> json, {
    List<Report>? recentSubmissions,
  }) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      totalReports: json['totalReports'] ?? 0,
      fixedReports: json['fixedReports'] ?? 0,
      impactPoints: json['impactPoints'] ?? 0,
      recentSubmissions: recentSubmissions ?? [],
    );
  }
}
