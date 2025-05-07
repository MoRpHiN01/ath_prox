// lib/services/wifi_service.dart
import 'package:network_info_plus/network_info_plus.dart';

class WifiService {
  final NetworkInfo _networkInfo = NetworkInfo();

  Future<void> checkWifiStatus() async {
    final name = await getSSID();
    final ip = await getCurrentIP();
    if (name == "Unknown SSID" || ip == "Unknown IP") {
      print("[WIFI] Not connected");
    } else {
      print("[WIFI] Connected to $name ($ip)");
    }
  }

  Future<String> getSSID() async {
    return (await _networkInfo.getWifiName()) ?? "Unknown SSID";
  }

  Future<String> getCurrentIP() async {
    return (await _networkInfo.getWifiIP()) ?? "Unknown IP";
  }

  // Optional: make getters for easier use in UI
  Future<Map<String, String>> getMetadata() async {
    return {
      "ssid": await getSSID(),
      "ip": await getCurrentIP(),
    };
  }
}
