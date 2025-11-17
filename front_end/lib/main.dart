import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/alerts/alerts_screen.dart';
import 'screens/activity/daily_activity_screen.dart';
import 'screens/vitals/vitals_detail_screen.dart';
import 'screens/session/start_session_screen.dart';
import 'screens/session/session_history_screen.dart';
import 'screens/nutrition/nutrition_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/sync_service.dart';
import 'providers/auth_provider.dart';
import 'providers/vitals_provider.dart';
import 'providers/bluetooth_provider.dart';
import 'providers/alerts_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    print(Firebase.app().options.apiKey);

  } catch (e) {
    debugPrint('Failed to initialize Firebase: $e');
  }
  
  // Initialize sqflite for desktop platforms only (not web)
  if (!kIsWeb) {
    try {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    } catch (e) {
      debugPrint('Failed to initialize sqflite_ffi: $e');
    }
  }
  
  // Initialize services
  try {
    await DatabaseService().database; // Initialize database
  } catch (e) {
    debugPrint('Failed to initialize database: $e');
  }
  
  try {
    await NotificationService().initialize(); // Initialize notifications
  } catch (e) {
    debugPrint('Failed to initialize notifications: $e');
  }
  
  // Initialize background sync service
  try {
    await SyncService().initialize(); // Initialize cloud sync
    debugPrint('✅ SyncService initialized - daily sync scheduled');
  } catch (e) {
    debugPrint('⚠️  Failed to initialize SyncService: $e (continuing without cloud sync)');
  }
  
  runApp(const HealthTrackApp());
}

class HealthTrackApp extends StatelessWidget {
  const HealthTrackApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => DatabaseService()),
        Provider(create: (_) => NotificationService()),
        
        // State Management Providers
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VitalsProvider()),
        ChangeNotifierProvider(create: (_) => BluetoothProvider()),
        ChangeNotifierProvider(create: (_) => AlertsProvider()),
      ],
      child: MaterialApp(
        title: 'HealthTrack Wearable',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/onboarding': (context) => const OnboardingFlow(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/alerts': (context) => const AlertsScreen(),
          '/daily-activity': (context) => const DailyActivityScreen(),
          '/vitals-detail': (context) => const VitalsDetailScreen(),
          '/start-session': (context) => const StartSessionScreen(),
          '/session-history': (context) => const SessionHistoryScreen(),
          '/nutrition': (context) => const NutritionScreen(),
          '/chat': (context) => const ChatScreen(),
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          );
        },
      ),
    );
  }
}
