// lib/services/ble_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/peer.dart';

class BleService {
  static final instanceId = const Uuid().v4();
  final _flutterBlue = FlutterBluePlus.instance;
  final _blePeripheral = FlutterBlePeripheral();
  StreamSubscription<ScanResult>? _scanSub;

  final void Function(Peer) onPeerDiscovered;
  final void Function(Object)? onError;

  BleService({required this.onPeerDiscovered, this.onError});

  Future<void> startAdvertising(String displayName, String status) async {
    final payload = {
      'instanceId': instanceId,
      'displayName': displayName,
      'status': status,
    };

    final advData = AdvertiseData(
      manufacturerId: 0xFFFF,
      manufacturerData: utf8.encode(jsonEncode(payload)),
    );

    await _blePeripheral.start(advertiseData: advData);
  }

  Future<void> stopAdvertising() async {
    await _blePeripheral.stop();
  }

  Future<void> startScan() async {
    try {
      await _flutterBlue.startScan();
      _scanSub = _flutterBlue.scanResults.listen((results) {
        for (final result in results) {
          final peer = Peer.fromAdvertisement(result);
          if (peer != null && peer.instanceId != instanceId) {
            onPeerDiscovered(peer);
          }
        }
      });
    } catch (e) {
      onError?.call(e);
    }
  }

  Future<void> stopScan() async {
    await _scanSub?.cancel();
    await _flutterBlue.stopScan();
  }
}
