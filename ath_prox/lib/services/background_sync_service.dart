// lib/services/background_sync_service.dart

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'session_sync_service.dart';
import '../utils/firebase_utils.dart';

@pragma('vm:entry-point')
Future<void> initializeBackgroundSync() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebaseIfNeeded();

  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      initialNotificationTitle: 'ATH > PROXIMITY',
      initialNotificationContent: 'Background sync active...',
      notificationChannelId: 'background_sync_channel',
    ),
    iosConfiguration: IosConfiguration(
      onForeground: (_) async => true,
      onBackground: (_) async => true,
    ),
  );

  await service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebaseIfNeeded();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  Timer.periodic(const Duration(minutes: 5), (timer) async {
    if (service is AndroidServiceInstance && !(await service.isForegroundService())) return;

    final allSessions = await SessionSyncService.getSyncedSessions();
    await SessionSyncService.syncSessions(allSessions);

    final msg = "Synced ${allSessions.length} sessions at ${DateTime.now()}";
    service.invoke("sync", {"status": msg});
  });
}
