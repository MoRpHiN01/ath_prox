// lib/services/background_service.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
//import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//import 'package:fluttertoast/fluttertoast.dart';
import '../models/session.dart';
import 'session_sync_service.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'proximity_channel',
      initialNotificationTitle: 'ATH > PROXIMITY',
      initialNotificationContent: 'Initializing background sync...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  await service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  Timer.periodic(const Duration(minutes: 5), (timer) async {
    if (service is AndroidServiceInstance && !await service.isForegroundService()) {
      return;
    }

    // 🧪 Simulated session sync – Replace with real scanning logic
    final session = Session(
      deviceId: 'bg-sync-${DateTime.now().millisecondsSinceEpoch}',
      deviceName: 'Simulated Device',
      startTime: DateTime.now().subtract(const Duration(minutes: 2)),
      endTime: DateTime.now(),
      status: SessionStatus.completed,
    );

    await SessionSyncService.syncSessions([session]);

    final statusText = 'Synced @ ${DateTime.now().toIso8601String()}';
    debugPrint('[BACKGROUND SYNC] $statusText');

    service.invoke("sync", {'message': statusText});

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "ATH > PROXIMITY",
        content: statusText,
      );
    }
  });
}

@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}
