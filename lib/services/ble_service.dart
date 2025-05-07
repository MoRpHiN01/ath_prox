// lib/services/ble_service.dart

import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  /// Stream of all scan results
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  /// Start BLE scan with more aggressive settings to ensure detection
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      await FlutterBluePlus.startScan(timeout: timeout);
      print('[BLE_SERVICE] Scanning started');
    } catch (e) {
      print('[BLE_SERVICE] Error starting scan: $e');
    }
  }

  /// Stop BLE scan
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      print('[BLE_SERVICE] Scanning stopped');
    } catch (e) {
      print('[BLE_SERVICE] Error stopping scan: $e');
    }
  }

  /// Extract the user display name from manufacturer data
  String extractDisplayName(ScanResult result) {
    try {
      final data = result.advertisementData.manufacturerData.values.first;
      final jsonStr = utf8.decode(data);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return map['user'] as String? ?? result.device.name;
    } catch (_) {
      return result.device.name.isNotEmpty
          ? result.device.name
          : result.device.remoteId.id;
    }
  }

  /// Extract the session status from manufacturer data
  String extractStatus(ScanResult result) {
    try {
      final data = result.advertisementData.manufacturerData.values.first;
      final jsonStr = utf8.decode(data);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return map['status'] as String? ?? 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }
}
