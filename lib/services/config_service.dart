import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  final _storage = const FlutterSecureStorage();

  // Environment Variables
  String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  String get googleClientId => dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
  String get googleServerClientId => dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '';
  String get youtubeApiKey => dotenv.env['YOUTUBE_API_KEY'] ?? '';
  String get youtubeChannelId => dotenv.env['YOUTUBE_CHANNEL_ID'] ?? '';

  // Secure Storage Methods
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<void> saveUserCredentials({
    required String email,
    required String password,
  }) async {
    await _storage.write(key: 'user_email', value: email);
    await _storage.write(key: 'user_password', value: password);
  }

  Future<Map<String, String?>> getUserCredentials() async {
    final email = await _storage.read(key: 'user_email');
    final password = await _storage.read(key: 'user_password');
    return {
      'email': email,
      'password': password,
    };
  }

  Future<void> clearUserCredentials() async {
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'user_password');
  }

  // Validation Methods
  bool validateEnvironmentVariables() {
    // Only validate Supabase variables which are required for basic app functionality
    final requiredVars = [
      supabaseUrl,
      supabaseAnonKey,
    ];

    final missingVars = requiredVars.where((value) => value.isEmpty).toList();
    
    if (missingVars.isNotEmpty) {
      debugPrint('Missing required environment variables: ${missingVars.join(', ')}');
      return false;
    }
    
    return true;
  }
} 