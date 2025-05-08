import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../models/peer.dart';

class BleService {
  static final String instanceId = const Uuid().v4();

  final void Function(Peer) onPeerFound;
  final void Function(Object)? onError;
  StreamSubscription<List<ScanResult>>? _subscription;

  BleService({required this.onPeerFound, this.onError});

  Future<void> startScan() async {
    try {
      await FlutterBluePlus.scan(timeout: const Duration(seconds: 10));

      _subscription = FlutterBluePlus.onScanResults.listen((results) {
        for (final result in results) {
          final peer = Peer.fromAdvertisement(result);
          if (peer != null && peer.instanceId != instanceId) {
            onPeerFound(peer);
          }
        }
      });
    } catch (e) {
      Logger().e('BLE scan error: $e');
      onError?.call(e);
    }
  }

  Future<void> stopScan() async {
    await _subscription?.cancel();
    await FlutterBluePlus.stopScan();
  }

  Future<void> sendInvite(String targetId) async {
    Logger().i('Sending BLE invite to $targetId');
    // Implement invite logic here
  }
}
