import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'providers/auth_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/student_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
    // App tetap bisa jalan meski Firebase error untuk development
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Provider - untuk authentication dan user management
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          lazy: false, // Load immediately untuk check auth state
        ),
        
        // Student Provider - untuk manajemen data siswa
        ChangeNotifierProvider(
          create: (_) => StudentProvider(),
        ),
        
        // Progress Provider - untuk tracking progress ngaji
        ChangeNotifierProvider(
          create: (_) => ProgressProvider(),
        ),
      ],
      child: MaterialApp(
        // App configuration
        title: 'Ngajiku - Progress Ngaji',
        debugShowCheckedModeBanner: false,
        
        // Theme
        theme: AppTheme.lightTheme,
        
        // Initial screen
        home: const SplashScreen(),
        
        // Localization untuk bahasa Indonesia
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        
        // Supported locales
        locale: const Locale('id', 'ID'),
        supportedLocales: const [
          Locale('id', 'ID'), // Indonesian
          Locale('en', 'US'), // English (fallback)
        ],
        
        // Global MediaQuery configuration
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              // Disable text scaling untuk konsistensi UI
              textScaleFactor: 1.0,
            ),
            child: child ?? Container(),
          );
        },
        
        // Global navigation key (untuk navigation dari provider)
        navigatorKey: GlobalKey<NavigatorState>(),
        
        // Route configuration (untuk deep linking di masa depan)
        onGenerateRoute: (settings) {
          // Custom route handling bisa ditambah di sini
          return null;
        },
        
        // Global error handling
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text('Halaman tidak ditemukan'),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Global error handler (opsional)
class GlobalErrorHandler {
  static void initialize() {
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
    };
  }
}

// App lifecycle handler (opsional)
class AppLifecycleHandler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('App resumed');
        break;
      case AppLifecycleState.inactive:
        debugPrint('App inactive');
        break;
      case AppLifecycleState.paused:
        debugPrint('App paused');
        break;
      case AppLifecycleState.detached:
        debugPrint('App detached');
        break;
      case AppLifecycleState.hidden:
        debugPrint('App hidden');
        break;
    }
  }
}