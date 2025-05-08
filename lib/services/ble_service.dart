// lib/services/ble_service.dart

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../models/peer.dart';

/// BLE Central (scanner) service.
class BleService {
  static final String instanceId = const Uuid().v4();

  final void Function(Peer) onPeerFound;
  final void Function(Object)? onError;
  StreamSubscription<List<ScanResult>>? _subscription;

  BleService({required this.onPeerFound, this.onError});

  /// Start BLE scan (always run on both SDKs).
  void startScan() {
    final flutterBlue = FlutterBluePlus.instance;
    try {
      flutterBlue.startScan(
        timeout: const Duration(seconds: 10),
        scanMode: ScanMode.lowLatency,
        allowDuplicates: true,
      );
      _subscription = flutterBlue.scanResults.listen((results) {
        for (final result in results) {
          final peer = Peer.fromAdvertisement(result);
          if (peer != null && peer.instanceId != instanceId) {
            onPeerFound(peer);
          }
        }
      });
    } on PlatformException catch (e) {
      Logger().e('BLE scan error: ${e.code}');
      onError?.call(e);
    }
  }

  /// Stop BLE scan.
  void stopScan() {
    _subscription?.cancel();
    FlutterBluePlus.instance.stopScan();
  }

  /// Ble-based invite (not implemented yet).
  Future<void> sendInvite(String targetId) async {
    Logger().i('Sending BLE invite to $targetId');
  }
}
