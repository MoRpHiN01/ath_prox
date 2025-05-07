// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'firebase_options.dart';
import 'models/user_model.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/about_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/support_screen.dart';
import 'screens/report_screen.dart';
import 'utils/themes.dart';
//import 'services/background_sync_service.dart';
import 'utils/firebase_utils.dart'; // 👈 NEW

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebaseIfNeeded();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserModel(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ATH > PROXIMITY',
        theme: appTheme,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/about': (context) => const AboutScreen(),
          '/support': (context) => const SupportScreen(),
          '/reports': (context) => const ReportScreen(),
        },
      ),
    );
  }
}
