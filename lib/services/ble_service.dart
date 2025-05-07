// lib/services/ble_service.dart

import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  final Stream<List<ScanResult>> scanResults = FlutterBluePlus.scanResults;

  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      print("[BLE_SERVICE] Starting scan...");
      await FlutterBluePlus.startScan(timeout: timeout);
      print("[BLE_SERVICE] Scanning started");
    } catch (e) {
      print("[BLE_SERVICE] Error starting scan: $e");
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      print("[BLE_SERVICE] Scanning stopped");
    } catch (e) {
      print("[BLE_SERVICE] Error stopping scan: $e");
    }
  }

  String extractDisplayName(ScanResult result) {
    try {
      final data = result.advertisementData.manufacturerData.values.first;
      final jsonStr = utf8.decode(data);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return _sanitize(map['user'] as String? ?? result.device.name);
    } catch (_) {
      return _sanitize(result.device.name.isNotEmpty ? result.device.name : result.device.remoteId.id);
    }
  }

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

  String extractInstanceId(ScanResult result) {
    try {
      final data = result.advertisementData.manufacturerData.values.first;
      final jsonStr = utf8.decode(data);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return map['instanceId'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }

  bool isAthProxPacket(ScanResult result) {
    try {
      final data = result.advertisementData.manufacturerData.values.first;
      final map = jsonDecode(utf8.decode(data));
      return map['proto'] == 'ath-prox-v1';
    } catch (_) {
      return false;
    }
  }

  String _sanitize(String? name) {
    final clean = (name ?? '').replaceAll(RegExp(r'[\x00-\x1F]'), '').trim();
    return clean.isEmpty ? "Unknown Device" : clean;
  }
}
