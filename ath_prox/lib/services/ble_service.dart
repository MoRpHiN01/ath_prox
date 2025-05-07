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

  /// Extracts the custom display name from manufacturer data, if encoded in JSON.
  String extractDisplayName(ScanResult result) {
    final data = result.advertisementData.manufacturerData;
    if (data.isNotEmpty) {
      final payload = data.entries.first.value;
      try {
        final decoded = utf8.decode(payload);
        final json = jsonDecode(decoded);
        return _sanitizeName(json['user'] ?? "Unknown");
      } catch (_) {
        return String.fromCharCodes(payload); // fallback
      }
    }
    return "Unknown Device";
  }

  /// Extracts the encoded status string from manufacturer data, e.g. "available", "pending", etc.
  String extractStatus(ScanResult result) {
    final data = result.advertisementData.manufacturerData;
    if (data.isNotEmpty) {
      final payload = data.entries.first.value;
      try {
        final decoded = utf8.decode(payload);
        final json = jsonDecode(decoded);
        return json['status'] ?? "available";
      } catch (_) {
        return "available";
      }
    }
    return "available";
  }

  String _sanitizeName(String name) {
    final clean = name.replaceAll(RegExp(r'[\x00-\x1F]'), '').trim();
    return clean.isEmpty ? "Unknown Device" : clean;
  }
}
