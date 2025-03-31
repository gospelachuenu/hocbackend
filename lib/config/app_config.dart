import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // YouTube Configuration
  static String get youtubeApiKey => dotenv.env['YOUTUBE_API_KEY'] ?? '';
  static const String youtubeChannelId = 'UCVauh-QZp6rtzmsHHHwYpvA';
  
  // Google Sign In Configuration
  static String get googleClientId => dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
  static String get googleServerClientId => dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '';
  
  // App Configuration
  static const String appName = 'House of Christ';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
} 