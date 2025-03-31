import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/supabase_config.dart';
import '../config/app_config.dart';
import 'dart:io';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get _client => Supabase.instance.client;
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: AppConfig.googleClientId,
    serverClientId: AppConfig.googleServerClientId,
  );

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      print('Error signing in with email: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: SupabaseConfig.redirectUrl,
      );
      return response;
    } catch (e) {
      print('Error signing up: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('No access token or ID token received from Google');
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      return response;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _client.auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      
      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String firstName,
    required String lastName,
    required String phone,
    String? imageUrl,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user logged in');

      await _client.from('profiles').upsert({
        'id': user.id,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'avatar_url': imageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Upload profile image
  Future<String> uploadProfileImage(File image) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user logged in');

      final fileExt = image.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'gif'].contains(fileExt)) {
        throw Exception('Invalid file type. Only jpg, jpeg, png, and gif are allowed.');
      }

      // Use a simpler path structure
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      print('Uploading file: $fileName'); // Debug print

      // First, check if the file exists and delete it if it does
      try {
        final List<FileObject> files = await _client.storage
            .from('avatars')
            .list();
        
        if (files.isNotEmpty) {
          for (var file in files) {
            if (file.name.startsWith(user.id)) {
              await _client.storage
                  .from('avatars')
                  .remove([file.name]);
              print('Removed old file: ${file.name}');
            }
          }
        }
      } catch (e) {
        print('Error checking/removing existing files: $e');
        // Continue with upload even if this fails
      }

      // Read file as bytes and validate size
      final bytes = await image.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) { // 5MB limit
        throw Exception('File size too large. Maximum size is 5MB.');
      }

      final String mimeType = 'image/$fileExt';
      print('Uploading file with mime type: $mimeType');

      // Upload the file to Supabase storage
      final response = await _client.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: mimeType
            ),
          );

      if (response.isEmpty) {
        throw Exception('Failed to upload image');
      }

      // Get the public URL
      final String publicUrl = _client.storage
          .from('avatars')
          .getPublicUrl(fileName);
      print('Public URL: $publicUrl'); // Debug print

      // Verify the file exists and is accessible
      try {
        final bytes = await _client.storage
            .from('avatars')
            .download(fileName);
        print('File verified (${bytes.length} bytes): $fileName');
        
        // Update profile with new avatar URL
        await updateUserProfile(
          firstName: (await getUserProfile())?['first_name'] ?? '',
          lastName: (await getUserProfile())?['last_name'] ?? '',
          phone: (await getUserProfile())?['phone'] ?? '',
          imageUrl: publicUrl,
        );
        print('Profile updated with new avatar URL');
      } catch (e) {
        print('Error verifying file: $e');
        rethrow;
      }

      return publicUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      rethrow;
    }
  }
} 