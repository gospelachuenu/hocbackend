import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'screens/signin_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/main_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/watch_live_screen.dart';
import 'screens/contact_us_screen.dart';
import 'screens/prayer_request_screen.dart';
import 'screens/testimony_screen.dart';
import 'screens/terms_conditions_screen.dart';
import 'screens/donation_screen.dart';
import 'services/config_service.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Load environment variables
    debugPrint('Loading environment variables...');
    await dotenv.load(fileName: ".env");
    debugPrint('Environment variables loaded successfully');
    
    // Debug: Print all environment variables
    debugPrint('SUPABASE_URL: ${dotenv.env['SUPABASE_URL']}');
    debugPrint('YOUTUBE_API_KEY: ${dotenv.env['YOUTUBE_API_KEY']}');
    debugPrint('YOUTUBE_CHANNEL_ID: ${dotenv.env['YOUTUBE_CHANNEL_ID']}');

    // Validate environment variables
    final configService = ConfigService();
    if (!configService.validateEnvironmentVariables()) {
      throw Exception('Missing required environment variables');
    }

    // Initialize Supabase
    await Supabase.initialize(
      url: configService.supabaseUrl,
      anonKey: configService.supabaseAnonKey,
    );
    debugPrint('Supabase initialized successfully');

    // Check initial connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      debugPrint('No internet connection available');
    }

    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        debugPrint('Lost internet connection');
      } else {
        debugPrint('Internet connection restored');
      }
    });

  } catch (e) {
    debugPrint('Error initializing app: $e');
    // Show error dialog to user
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize app',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    main();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return;
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'House of Christ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          primary: Colors.red,
        ),
        useMaterial3: true,
        primaryColor: Colors.red,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/main': (context) => const MainScreen(),
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/watch-live': (context) => const WatchLiveScreen(),
        '/contact-us': (context) => const ContactUsScreen(),
        '/prayer-requests': (context) => const PrayerRequestScreen(),
        '/testimony': (context) => const TestimonyScreen(),
        '/terms-conditions': (context) => const TermsConditionsScreen(),
        '/donation': (context) => const DonationScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        debugPrint('Auth state changed: ${snapshot.data?.event}');
        debugPrint('Has session: ${snapshot.data?.session != null}');
        
        if (snapshot.hasData) {
          final session = snapshot.data!.session;
          if (session != null) {
            debugPrint('User is authenticated, showing MainScreen');
            return const MainScreen();
          } else {
            debugPrint('No session, showing SignInScreen');
            return const SignInScreen();
          }
        }
        debugPrint('Waiting for auth state, showing loading');
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
