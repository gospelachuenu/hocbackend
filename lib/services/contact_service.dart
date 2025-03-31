import 'package:supabase_flutter/supabase_flutter.dart';

class ContactService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> submitContactForm({
    required String name,
    required String email,
    required String message,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      print('Current user: ${user?.id}'); // Debug print
      print('Attempting to insert message with name: $name, email: $email'); // Debug print

      // Store the message in Supabase
      await _supabase.from('contact_messages').insert({
        'name': name,
        'email': email,
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      print('Message inserted successfully'); // Debug print
    } catch (e) {
      print('Error submitting contact form: $e');
      if (e is PostgrestException) {
        print('PostgrestException details:');
        print('Message: ${e.message}');
        print('Code: ${e.code}');
        print('Details: ${e.details}');
        print('Hint: ${e.hint}');
      }
      throw 'Failed to send message. Please try again.';
    }
  }
} 