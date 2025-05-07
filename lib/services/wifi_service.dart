// lib/services/ble_service.dart

import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart';

class BleService {
  final Stream<List<ScanResult>> scanResults = FlutterBluePlus.scanResults;

  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      debugPrint("[BLE_SERVICE] Starting scan...");
      await FlutterBluePlus.startScan(timeout: timeout);
      debugPrint("[BLE_SERVICE] Scan started");
    } catch (e) {
      debugPrint("[BLE_SERVICE] Scan start failed: $e");
    }
  }

  Future<void> stopScan() async {
    try {
      debugPrint("[BLE_SERVICE] Stopping scan...");
      await FlutterBluePlus.stopScan();
      debugPrint("[BLE_SERVICE] Scan stopped");
    } catch (e) {
      debugPrint("[BLE_SERVICE] Scan stop failed: $e");
    }
  }

  String? extractPeerId(ScanResult result) {
    try {
      final data = result.advertisementData.manufacturerData[0xFF];
      if (data == null) return null;
      final map = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      return map['instanceId'] as String?;
    } catch (e) {
      debugPrint("[BLE_SERVICE] extractPeerId error: $e");
      return null;
    }
  }

  String extractDisplayName(ScanResult result) {
    try {
      final data = result.advertisementData.manufacturerData[0xFF];
      if (data == null) return _fallbackName(result);
      final map = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      return _sanitizeName(map['user'] as String? ?? _fallbackName(result));
    } catch (e) {
      debugPrint("[BLE_SERVICE] extractDisplayName error: $e");
      return _fallbackName(result);
    }
  }

  String extractStatus(ScanResult result) {
    try {
      final data = result.advertisementData.manufacturerData[0xFF];
      if (data == null) return 'unknown';
      final map = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      return map['status'] as String? ?? 'unknown';
    } catch (e) {
      debugPrint("[BLE_SERVICE] extractStatus error: $e");
      return 'unknown';
    }
  }

  String _fallbackName(ScanResult result) {
    final fallback = result.device.name.isNotEmpty ? result.device.name : result.device.remoteId.str;
    return _sanitizeName(fallback);
  }

  String _sanitizeName(String name) {
    final clean = name.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();
    return clean.isEmpty ? "Unknown Device" : clean;
  }
}
