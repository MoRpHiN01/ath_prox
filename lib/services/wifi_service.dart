// lib/services/wifi_service.dart

import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';

/// Service for querying Wi‑Fi network metadata
class WifiService {
  final NetworkInfo _networkInfo = NetworkInfo();

  /// Logs the current Wi‑Fi SSID and IP, or notes if not connected
  Future<void> checkWifiStatus() async {
    final ssid = await getSSID() ?? 'Unknown SSID';
    final ip = await getCurrentIP() ?? 'Unknown IP';
    if (ssid == 'Unknown SSID' || ip == 'Unknown IP') {
      print('[WIFI] Not connected');
    } else {
      print('[WIFI] Connected to $ssid ($ip)');
    }
  }

  /// Returns the current Wi‑Fi SSID, or null if unavailable
  Future<String?> getSSID() async {
    return await _networkInfo.getWifiName();
  }

  /// Returns the device’s IPv4 address on the Wi‑Fi network, or null
  Future<String?> getCurrentIP() async {
    return await _networkInfo.getWifiIP();
  }

  /// Convenience getter for both SSID and IP in one call
  Future<Map<String, String?>> getMetadata() async {
    return {
      'ssid': await getSSID(),
      'ip': await getCurrentIP(),
    };
  }
}
