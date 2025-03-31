import 'package:supabase_flutter/supabase_flutter.dart';

class PrayerRequestService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getPrayerRequests() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('prayer_requests')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching prayer requests: $e');
      rethrow;
    }
  }

  Future<void> submitPrayerRequest({
    required String request,
    required String name,
    required bool isAnonymous,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Ensure name is properly handled
      final String? submittedName = isAnonymous ? null : (name.isEmpty ? null : name.trim());

      final data = {
        'user_id': user.id,
        'request': request.trim(),
        'name': submittedName,
        'is_anonymous': isAnonymous,
      };

      print('Debug - Final prayer request data being sent to Supabase:');
      print('Debug - user_id: ${data['user_id']}');
      print('Debug - name: ${data['name']}');
      print('Debug - is_anonymous: ${data['is_anonymous']}');
      print('Debug - request: ${data['request']}');

      final response = await _supabase
          .from('prayer_requests')
          .insert(data)
          .select()
          .single();

      print('Debug - Supabase response after insert: $response');
    } catch (e, stackTrace) {
      print('Error submitting prayer request: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> deletePrayerRequest(String id) async {
    try {
      await _supabase.from('prayer_requests').delete().eq('id', id);
    } catch (e) {
      print('Error deleting prayer request: $e');
      rethrow;
    }
  }
} 