import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/config/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

bool _isFirebaseInitialized = false;
bool _isSupabaseInitialized = false;

final firebaseInitializedProvider = Provider<bool>((ref) => _isFirebaseInitialized);
final supabaseInitializedProvider = Provider<bool>((ref) => _isSupabaseInitialized);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: Failed to load .env file. $e");
  }

  // Initialize Firebase (for Cloud Messaging push notifications)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    _isFirebaseInitialized = true;
  } catch (e) {
    _isFirebaseInitialized = false;
    debugPrint("Firebase initialization error: $e");
  }

  // Initialize Supabase
  try {
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    String? supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (supabaseAnonKey == null || supabaseAnonKey.isEmpty || supabaseAnonKey == 'your-supabase-anon-key') {
      supabaseAnonKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY'];
    }

    if (supabaseUrl != null && supabaseAnonKey != null && supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: supabaseAnonKey,
      );
      _isSupabaseInitialized = true;
    } else {
      _isSupabaseInitialized = false;
      debugPrint("Warning: Supabase credentials missing in .env");
    }
  } catch (e) {
    _isSupabaseInitialized = false;
    debugPrint("Supabase initialization error: $e");
  }

  runApp(
    ProviderScope(
      overrides: [
        firebaseInitializedProvider.overrideWithValue(_isFirebaseInitialized),
        supabaseInitializedProvider.overrideWithValue(_isSupabaseInitialized),
      ],
      child: const NationalAcademyApp(),
    ),
  );
}

class NationalAcademyApp extends ConsumerWidget {
  const NationalAcademyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSupabaseInitialized = ref.watch(supabaseInitializedProvider);
    final router = ref.watch(routerProvider);

    if (!isSupabaseInitialized) {
      debugPrint("Warning: Supabase is not initialized. Using Offline Mock Repository Fallback.");
    }

    return MaterialApp.router(
      title: 'National Academy',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
