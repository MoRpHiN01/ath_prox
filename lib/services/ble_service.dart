import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  final StreamController<ScanResult> _resultController = StreamController<ScanResult>.broadcast();

  Stream<ScanResult> get scanResults => _resultController.stream;

  Future<void> startScan() async {
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          _resultController.add(result);
        }
      }, onError: (e) {
        print('[BLE_SERVICE] Scan error: $e');
      });
      print('[BLE_SERVICE] Scan started');
    } catch (e) {
      print('[BLE_SERVICE] Failed to start scan: $e');
      rethrow;
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      print('[BLE_SERVICE] Scan stopped');
    } catch (e) {
      print('[BLE_SERVICE] Failed to stop scan: $e');
    }
  }

  String extractInstanceId(ScanResult result) {
    try {
      final data = result.advertisementData.manufacturerData.values.first;
      final decoded = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      return decoded['instanceId'] ?? result.device.id.id;
    } catch (_) {
      return result.device.id.id;
    }
  }

  String extractDisplayName(ScanResult result) {
    try {
      final data = result.advertisementData.manufacturerData.values.first;
      final decoded = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      return decoded['user'] ?? 'User';
    } catch (_) {
      return 'User';
    }
  }

  String extractType(ScanResult result) {
    try {
      final data = result.advertisementData.manufacturerData.values.first;
      final decoded = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      return decoded['type'] ?? 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  String extractTargetId(ScanResult result) {
    try {
      final data = result.advertisementData.manufacturerData.values.first;
      final decoded = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      return decoded['targetId'] ?? '';
    } catch (_) {
      return '';
    }
  }

  void dispose() {
    _resultController.close();
  }
}
