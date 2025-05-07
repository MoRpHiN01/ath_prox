// lib/services/ble_service.dart

import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  Stream<ScanResult> startScan({Duration timeout = const Duration(seconds: 10)}) {
    FlutterBluePlus.startScan(timeout: timeout);
    return FlutterBluePlus.scanResults.asyncExpand((list) => Stream.fromIterable(list));
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print("[BLE_SERVICE] Error stopping scan: $e");
    }
  }

  String? extractInstanceId(ScanResult result) {
    try {
      final data = result.advertisementData.manufacturerData[0xFF];
      if (data == null) return null;
      final decoded = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      return decoded['instanceId'] as String?;
    } catch (e) {
      print("[BLE_SERVICE] extractInstanceId error: $e");
      return null;
    }
  }

  String? extractUser(ScanResult result) {
    try {
      final data = result.advertisementData.manufacturerData[0xFF];
      if (data == null) return null;
      final decoded = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      return decoded['user'] as String?;
    } catch (_) {
      return null;
    }
  }

  String? extractType(ScanResult result) {
    try {
      final data = result.advertisementData.manufacturerData[0xFF];
      if (data == null) return null;
      final decoded = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      return decoded['type'] as String?;
    } catch (_) {
      return null;
    }
  }
}
