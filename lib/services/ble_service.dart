// lib/services/ble_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  final Stream<List<ScanResult>> scanResults = FlutterBluePlus.scanResults;

  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      await FlutterBluePlus.startScan(timeout: timeout);
    } catch (e) {
      print('[BLE_SERVICE] Start scan failed: $e');
      rethrow;
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print('[BLE_SERVICE] Stop scan failed: $e');
    }
  }

  String extractDisplayName(ScanResult result) {
    try {
      final data = result.advertisementData.manufacturerData.values.first;
      final decoded = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      return decoded['user'] as String? ?? 'User';
    } catch (_) {
      return 'User';
    }
  }

  String extractStatus(ScanResult result) {
    try {
      final data = result.advertisementData.manufacturerData.values.first;
      final decoded = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      return decoded['status'] as String? ?? 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  String? extractInstanceId(ScanResult result) {
    try {
      final data = result.advertisementData.manufacturerData.values.first;
      final decoded = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      return decoded['instanceId'] as String?;
    } catch (_) {
      return null;
    }
  }

  String? extractType(ScanResult result) {
    try {
      final data = result.advertisementData.manufacturerData.values.first;
      final decoded = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      return decoded['type'] as String?;
    } catch (_) {
      return null;
    }
  }
}
