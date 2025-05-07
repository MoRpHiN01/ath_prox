import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'session_sync_service.dart';

class ForegroundServiceManager {
  static final FlutterBackgroundService _service = FlutterBackgroundService();
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'background_service_channel',
      'Background Service',
      description: 'ATH > PROXIMITY background service running',
      importance: Importance.defaultImportance,
    );

    if (Platform.isAndroid) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'background_service_channel',
        initialNotificationTitle: 'ATH > PROXIMITY',
        initialNotificationContent: 'Waiting for sync...',
      ),
      iosConfiguration: IosConfiguration(
        onForeground: (_) async => true,
        onBackground: (_) async => true,
      ),
    );

    await _service.startService();
  }

  static Future<void> stop() async {
    _service.invoke("stopService");
  }

  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) {
    WidgetsFlutterBinding.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }

    // Listen for stop requests
    service.on("stopService").listen((event) {
      service.stopSelf();
    });

    Timer.periodic(const Duration(seconds: 30), (timer) async {
      final sessions = await SessionSyncService.getSyncedSessions();
      final latestStatus = sessions.isNotEmpty
          ? "Synced ${sessions.length} sessions"
          : "No new sessions to sync";

      await SessionSyncService.syncSessions(sessions);

      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'ATH > PROXIMITY',
          content: latestStatus,
        );
      }

      service.invoke('background_sync', {'status': latestStatus});
    });
  }
}
