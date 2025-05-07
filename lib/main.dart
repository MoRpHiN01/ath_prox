// lib/main.dart

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import 'models/user_model.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/about_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/support_screen.dart';
import 'screens/report_screen.dart';
import 'services/background_sync_service.dart';
import 'utils/themes.dart';
import 'utils/firebase_utils.dart';

/// Entry point for the application
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeFirebaseIfNeeded();

  // Set up notification channel for the foreground service
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const serviceChannel = AndroidNotificationChannel(
    'bg_service_ch',
    'Background Service',
    description: 'This channel is used for background service notifications',
    importance: Importance.low,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(serviceChannel);

  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: serviceChannel.id,
      initialNotificationTitle: 'ATH Proximity',
      initialNotificationContent: 'Service running',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: <AndroidForegroundType>[
        AndroidForegroundType.location,
        AndroidForegroundType.connectedDevice,
      ],
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

/// Background service entry-point
@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  // Avoid calling DartPluginRegistrant here to prevent isolate errors
  // TODO: Add your background logic (e.g., BLE scanning, sync) using ServiceInstance
}

/// iOS background fetch handler
Future<bool> onIosBackground(ServiceInstance service) async {
  // iOS background fetch logic (optional)
  return true;
}

/// Main application widget
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
