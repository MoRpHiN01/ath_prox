import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/peer.dart';

class BleService {
  static final String instanceId = const Uuid().v4();
  final FlutterBluePlus _ble = FlutterBluePlus();
  final void Function(Peer) onPeerFound;
  final void Function(Object error)? onError;

  StreamSubscription<List<ScanResult>>? _scanSub;

  BleService({required this.onPeerFound, this.onError});

  Future<void> startScan() async {
    try {
      _scanSub = _ble.scanResults.listen((results) {
        for (final result in results) {
          final peer = Peer.fromAdvertisement(result);
          if (peer != null && peer.instanceId != instanceId) {
            onPeerFound(peer);
          }
        }
      });
      await _ble.startScan();
    } catch (e) {
      onError?.call(e);
    }
  }

  Future<void> stopScan() async {
    await _scanSub?.cancel();
    await _ble.stopScan();
  }
}