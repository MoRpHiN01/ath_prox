// lib/services/ble_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../models/peer.dart';

class BleService {
  static final String instanceId = const Uuid().v4();

  final void Function(Peer) onPeerFound;
  final void Function(Object)? onError;
  StreamSubscription<List<ScanResult>>? _subscription;

  final FlutterBlePeripheral blePeripheral = FlutterBlePeripheral();

  BleService({required this.onPeerFound, this.onError});

  Future<void> startScan() async {
    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
      );

      _subscription = FlutterBluePlus.scanResults.listen((results) {
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

  Future<void> startAdvertising({
    required String displayName,
    required String status,
  }) async {
    try {
      final payload = _generateBleAdvertisementPayload(
        instanceId: instanceId,
        displayName: displayName,
        status: status,
      );

      await blePeripheral.start(advertiseData: AdvertiseData(
        includeDeviceName: false,
        manufacturerId: 0xFFFF,
        manufacturerData: payload,
      ));

      Logger().i('Started BLE advertising for $displayName [$status]');
    } catch (e) {
      Logger().e('BLE advertising error: $e');
      onError?.call(e);
    }
  }

  Future<void> stopAdvertising() async {
    await blePeripheral.stop();
    Logger().i('Stopped BLE advertising');
  }

  Future<void> sendInvite(String peerId) async {
    Logger().i('BLE invite sent to $peerId (placeholder)');
  }

  Uint8List _generateBleAdvertisementPayload({
    required String instanceId,
    required String displayName,
    required String status,
  }) {
    final jsonMap = {
      'instanceId': instanceId,
      'displayName': displayName,
      'status': status,
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(jsonMap)));
  }
}
