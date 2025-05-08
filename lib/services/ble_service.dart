// lib/services/ble_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/peer.dart';
import '../models/session.dart';
import 'session_service.dart';

class BleService {
  static final String instanceId = const Uuid().v4();
  final FlutterBluePlus _flutterBlue = FlutterBluePlus();
  final SessionService _sessionService = SessionService();

  StreamSubscription<ScanResult>? _scanSubscription;
  bool _isAdvertising = false;

  Future<void> startScan(Function(Peer) onPeerFound) async {
    await _flutterBlue.startScan(timeout: const Duration(seconds: 10));
    _scanSubscription = _flutterBlue.scanResults.listen((results) {
      for (final result in results) {
        final peer = Peer.fromAdvertisement(result);
        if (peer != null && peer.instanceId != instanceId) {
          onPeerFound(peer);
        }
      }
    });
  }

  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    await _flutterBlue.stopScan();
  }

  Future<void> startAdvertising(String displayName, String status) async {
    final payload = _buildAdvertisingPayload(displayName, status);
    await _flutterBlue.startAdvertising(advertiseData: AdvertiseData(
      manufacturerData: {0xFFFF: payload},
      serviceUuids: [Guid(Peer.serviceUuid)],
    ));
    _isAdvertising = true;
  }

  Future<void> stopAdvertising() async {
    await _flutterBlue.stopAdvertising();
    _isAdvertising = false;
  }

  Uint8List _buildAdvertisingPayload(String displayName, String status) {
    final map = {
      'instanceId': instanceId,
      'displayName': displayName,
      'status': status,
    };
    final jsonStr = jsonEncode(map);
    return Uint8List.fromList(utf8.encode(jsonStr));
  }

  bool get isAdvertising => _isAdvertising;

  void dispose() {
    stopScan();
    stopAdvertising();
  }
}