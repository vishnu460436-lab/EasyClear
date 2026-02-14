import 'package:easyclear/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // Signup method
  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': name},
      );

      final user = res.user;

      if (user != null) {
        return {
          'success': true,
          'data': {'role': 'user'},
          'message': 'Account created successfully',
        };
      }
      return {'success': false, 'message': 'Signup failed. Please try again.'};
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } on PostgrestException catch (e) {
      return {'success': false, 'message': 'Database Error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  // login method
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final AuthResponse res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = res.user;

      if (user != null) {
        // Fetch user profile
        try {
          final profile = await supabase
              .from('profiles')
              .select()
              .eq('id', user.id)
              .single();

          return {
            'success': true,
            'data': profile,
            'message': 'Login successful',
          };
        } catch (e) {
          // If profile fetch fails but auth succeeded, return success but default role
          return {
            'success': true,
            'data': {'role': 'user'},
            'message': 'Login successful (Profile not found)',
          };
        }
      }
      return {
        'success': false,
        'message': 'Login failed. Please check your credentials.',
      };
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } on PostgrestException catch (e) {
      return {'success': false, 'message': 'Database Error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  // logout method
  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  // Get current user
  User? get currentUser => supabase.auth.currentUser;
}
