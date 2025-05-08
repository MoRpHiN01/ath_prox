// lib/services/background_service.dart
import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ble_service.dart';
import 'nfc_service.dart';
import 'wifi_service.dart';
import '../models/peer.dart';

class BackgroundServiceManager {
  static final BackgroundServiceManager _instance = BackgroundServiceManager._internal();

  factory BackgroundServiceManager() => _instance;

  BackgroundServiceManager._internal();

  final BleService _bleService = BleService(
    onPeerFound: (peer) => _handlePeer(peer),
    onError: (err) => print('BLE error: $err'),
  );

  final NfcService _nfcService = NfcService(
    onPeerDetected: (peer) => _handlePeer(peer),
    onError: (err) => print('NFC error: $err'),
  );

  final WifiService _wifiService = WifiService(
    onPeerDetected: (peer) => _handlePeer(peer),
    onError: (err) => print('Wi-Fi error: $err'),
  );

  static void _handlePeer(Peer peer) {
    // Handle sync logic: update session, notify user, etc.
    print('🔁 Peer Detected: ${peer.displayName} [${peer.status}]');
    // Extend this to update local DB or state management
  }

  Future<void> init() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'proximity_service',
        initialNotificationTitle: 'ATH Proximity Service',
        initialNotificationContent: 'Monitoring nearby devices...',
        foregroundServiceNotificationId: 4242,
      ),
      iosConfiguration: IosConfiguration(
        onForeground: _onStart,
        onBackground: () => true,
      ),
    );

    await service.startService();
  }

  static void _onStart(ServiceInstance service) async {
    final ble = BleService(
      onPeerFound: (peer) => _handlePeer(peer),
      onError: (err) => print('BLE error in background: $err'),
    );

    final nfc = NfcService(
      onPeerDetected: (peer) => _handlePeer(peer),
      onError: (err) => print('NFC error in background: $err'),
    );

    final wifi = WifiService(
      onPeerDetected: (peer) => _handlePeer(peer),
      onError: (err) => print('Wi-Fi error in background: $err'),
    );

    // Resume services
    await ble.startScan();
    await nfc.startSession();
    await wifi.startBroadcast();

    service.on('stopService').listen((event) async {
      await ble.stopScan();
      await nfc.stopSession();
      await wifi.stopBroadcast();
      await service.stopSelf();
    });

    Timer.periodic(const Duration(minutes: 5), (timer) async {
      service.invoke('update', {'status': 'running'});
    });
  }

  Future<void> stop() async {
    final service = FlutterBackgroundService();
    await _bleService.stopScan();
    await _nfcService.stopSession();
    await _wifiService.stopBroadcast();
    await service.invoke('stopService');
  }
}
