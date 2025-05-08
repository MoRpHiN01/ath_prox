// lib/services/background_sync_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

import 'session_sync_service.dart';
import '../utils/firebase_utils.dart';

HttpServer? _wifiServer;
const int _wifiPort = 8080;

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
      notificationChannelId: 'background_sync_channel',
      initialNotificationTitle: 'ATH Proximity',
      initialNotificationContent: 'Background sync active...',
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

  // Start Wi-Fi HTTP invite server
  _startWifiServer(service);

  // Periodic Firebase session sync
  Timer.periodic(const Duration(minutes: 5), (timer) async {
    if (service is AndroidServiceInstance && !(await service.isForegroundService())) {
      return;
    }
    final allSessions = await SessionSyncService.getSyncedSessions();
    await SessionSyncService.syncSessions(allSessions);
    final msg = 'Synced \${allSessions.length} sessions at \${DateTime.now()}';
    service.invoke('sync', {'status': msg});
  });
}

void _startWifiServer(ServiceInstance service) async {
  if (_wifiServer != null) return;
  try {
    _wifiServer = await HttpServer.bind(
      InternetAddress.anyIPv4,
      _wifiPort,
      shared: true,
    );
    _wifiServer!.listen((HttpRequest req) async {
      if (req.method == 'POST' && req.uri.path == '/invite') {
        try {
          final body = await utf8.decoder.bind(req).join();
          final data = jsonDecode(body) as Map<String, dynamic>;
          final from = data['from'] as String?;
          final sessionId = data['sessionId'] as String?;
          if (from != null && sessionId != null) {
            service.invoke('wifiInvite', {
              'from': from,
              'sessionId': sessionId,
            });
          }
          req.response
            ..statusCode = HttpStatus.ok
            ..write('OK');
        } catch (e) {
          req.response
            ..statusCode = HttpStatus.badRequest
            ..write('Error: \$e');
        }
      } else {
        req.response
          ..statusCode = HttpStatus.notFound
          ..write('Not Found');
      }
      await req.response.close();
    });
  } catch (e) {
    // Could not start server; log or handle error
    service.invoke('error', {'message': 'Wi-Fi server error: \$e'});
  }
}
