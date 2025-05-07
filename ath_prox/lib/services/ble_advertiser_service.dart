// lib/services/ble_advertiser_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BleAdvertiserService {
  static final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();
  static bool _isAdvertising = false;

  static Future<void> startAdvertising() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferredName = prefs.getString('preferredName') ?? "I AM HERE";

      final encodedName = Uint8List.fromList(preferredName.codeUnits.length > 20
          ? preferredName.substring(0, 20).codeUnits
          : preferredName.codeUnits);

      final advertiseData = AdvertiseData(
        includeDeviceName: true, // still useful on Android 10+
        manufacturerId: 0xACCE, // use unique ID for your app
        manufacturerData: Uint8List.fromList(utf8.encode(preferredName))
      );

      await _blePeripheral.start(advertiseData: advertiseData);
      _isAdvertising = true;
      prefs.setBool('ble_advertising', true);
    } catch (e) {
      _isAdvertising = false;
      print("[BLE_ADVERTISER] Error starting advertising: $e");
    }
  }

  static Future<void> stopAdvertising() async {
    try {
      await _blePeripheral.stop();
      _isAdvertising = false;
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('ble_advertising', false);
    } catch (e) {
      print("[BLE_ADVERTISER] Error stopping advertising: $e");
    }
  }

  static bool get isAdvertising => _isAdvertising;
}
