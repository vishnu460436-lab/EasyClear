import 'dart:io';
import 'package:easyclear/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/report_model.dart';

class ApiService {
  Future<UserModel> fetchUserProfile() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('No user logged in');
      }

      // Fetch profile data from Supabase
      final profileResponse = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      // Fetch actual counts from reports table
      // We fetch only IDs to keep it efficient
      final totalReportsResponse = await supabase
          .from('reports')
          .select('id')
          .eq('user_id', user.id);

      final totalReportsCount = (totalReportsResponse as List).length;

      final fixedReportsResponse = await supabase
          .from('reports')
          .select('id')
          .eq('user_id', user.id)
          .eq('status', 'fixed');

      final fixedReportsCount = (fixedReportsResponse as List).length;

      // Fetch recent reports from Supabase
      final reportsResponse = await supabase
          .from('reports')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(
            20,
          ); // Fetch more for the "View All" page if needed, but the model only keeps recentSubmissions

      // Convert reports JSON to Report objects
      final List<Report> recentReports = (reportsResponse as List)
          .map((data) => Report.fromJson(data))
          .toList();

      // Construct UserModel
      return UserModel(
        id: user.id.substring(0, 8).toUpperCase(),
        name: profileResponse['username'] ?? 'Community Member',
        location: profileResponse['location'] ?? 'Kochi, Kerala',
        avatarUrl:
            profileResponse['avatar_url'] ??
            'https://ui-avatars.com/api/?name=${profileResponse['username'] ?? 'User'}&background=random',
        totalReports: totalReportsCount,
        fixedReports: fixedReportsCount,
        impactPoints: profileResponse['impact_points'] ?? 0,
        recentSubmissions: recentReports,
      );
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  Future<void> submitReport({
    required String title,
    required String description,
    required String category,
    String? address,
    double? latitude,
    double? longitude,
    required File imageFile,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      // 1. Upload Image
      // Sanitize filename
      final fileExt = imageFile.path.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${user.id}/$timestamp.$fileExt';

      await supabase.storage
          .from('report-images')
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final imageUrl = supabase.storage
          .from('report-images')
          .getPublicUrl(filePath);

      // 2. Insert Report
      await supabase.from('reports').insert({
        'user_id': user.id,
        'title': title,
        'description': description,
        'category': category,
        'location_address': address,
        'latitude': latitude,
        'longitude': longitude,
        'image_url': imageUrl,
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }

  Future<String> updateProfileImage(File imageFile) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      // 1. Upload Image to 'avatars' bucket
      final fileExt = imageFile.path.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${user.id}/$timestamp.$fileExt';

      await supabase.storage
          .from('avatars')
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final imageUrl = supabase.storage.from('avatars').getPublicUrl(filePath);

      // 2. Update Profile table
      await supabase
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', user.id);

      return imageUrl;
    } catch (e) {
      throw Exception('Failed to update profile image: $e');
    }
  }

  Future<void> updateProfileName(String newName) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      await supabase
          .from('profiles')
          .update({'username': newName})
          .eq('id', user.id);
    } catch (e) {
      throw Exception('Failed to update profile name: $e');
    }
  }

  Future<void> deleteReport(String reportId) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      await supabase
          .from('reports')
          .delete()
          .eq('id', reportId)
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Failed to delete report: $e');
    }
  }

  // Admin Methods
  Future<List<Report>> fetchAllReports() async {
    try {
      final response = await supabase
          .from('reports')
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((data) => Report.fromJson(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch all reports: $e');
    }
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    try {
      await supabase
          .from('reports')
          .update({'status': status})
          .eq('id', reportId);
    } catch (e) {
      throw Exception('Failed to update report status: $e');
    }
  }
}
