import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  final Stream<List<ScanResult>> scanResults = FlutterBluePlus.scanResults;

  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      await FlutterBluePlus.startScan(timeout: timeout);
    } catch (e) {
      print("[BLE_SERVICE] Error starting scan: $e");
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print("[BLE_SERVICE] Error stopping scan: $e");
    }
  }

  String extractDisplayName(ScanResult result) {
    try {
      // pick up the first chunk of manufacturerData
      final data = result.advertisementData.manufacturerData.values.first;
      final jsonStr = utf8.decode(data);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return map['user'] as String? ?? result.device.name;
    } catch (_) {
      // fallback to the Bluetooth name or ID
      return result.device.name.isNotEmpty
          ? result.device.name
          : result.device.remoteId.id;
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

  String _sanitizeName(String name) {
    final clean = name.replaceAll(RegExp(r'[\x00-\x1F]'), '').trim();
    return clean.isEmpty ? "Unknown Device" : clean;
  }
}
