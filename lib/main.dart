// lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
import 'utils/firebase_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeFirebaseIfNeeded();
  
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,                        // your entry-point
      autoStart: true,                         // launches on boot
      isForegroundMode: true,                  // show a notification
      notificationChannelId: 'bg_service_ch',  // must match your channel
      initialNotificationTitle: 'ATH Proximity',
      initialNotificationContent: 'Service running',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
  service.startService();

  runApp(const MyApp());
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  DartPluginRegistrant.ensureInitialized();
  // …your background logic here…
}

Future<bool> onIosBackground(ServiceInstance service) async {
  // iOS background fetch logic, if needed
  return true;
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
