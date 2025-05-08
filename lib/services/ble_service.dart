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
  final Logger _logger = Logger();

  final FlutterBluePlus _bluetooth = FlutterBluePlus();
  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();

  StreamSubscription<ScanResult>? _scanSubscription;
  bool _isAdvertising = false;

  BleService({
    required this.onPeerFound,
    this.onError,
  });

  Future<void> startScan() async {
    try {
      await _bluetooth.startScan(timeout: const Duration(seconds: 10));
      _scanSubscription = _bluetooth.scanResults.listen((results) {
        for (final result in results) {
          final peer = Peer.fromAdvertisement(result);
          if (peer != null && peer.instanceId != instanceId) {
            onPeerFound(peer);
          }
        }
      });
    } catch (e) {
      _logger.e('BLE scan error: $e');
      onError?.call(e);
    }
  }

  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    await _bluetooth.stopScan();
  }

  Future<void> startAdvertising(String displayName, String status) async {
    if (_isAdvertising) return;

    try {
      final payload = Uint8List.fromList(utf8.encode(jsonEncode({
        'instanceId': instanceId,
        'displayName': displayName,
        'status': status,
      })));

      final data = AdvertiseData(
        includeDeviceName: false,
        manufacturerId: 0xFFFF,
        manufacturerData: payload,
      );

      final settings = AdvertiseSettings(
        advertiseMode: AdvertiseMode.advertiseModeLowLatency,
        txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh,
        timeout: 0,
      );

      await _blePeripheral.start(advertiseData: data, advertiseSettings: settings);
      _isAdvertising = true;
      _logger.i('Started advertising BLE packet');
    } catch (e) {
      _logger.e('BLE advertise error: $e');
      onError?.call(e);
    }
  }

  Future<void> stopAdvertising() async {
    if (!_isAdvertising) return;

    try {
      await _blePeripheral.stop();
      _isAdvertising = false;
      _logger.i('Stopped advertising BLE packet');
    } catch (e) {
      _logger.e('BLE stop advertising error: $e');
      onError?.call(e);
    }
  }

  Future<void> dispose() async {
    await stopScan();
    await stopAdvertising();
  }
}
