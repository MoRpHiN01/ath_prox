// lib/services/network_discovery_service.dart

import 'dart:convert';
import 'dart:io';

class NetworkDiscoveryService {
  static const int port = 9999;
  RawDatagramSocket? _socket;

  Future<void> start(String name) async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socket!.broadcastEnabled = true;

      final msg = jsonEncode({
        'proto': 'ath-prox-v1',
        'type': 'status',
        'user': name,
        'instanceId': '', // to be filled by caller
      });

      _socket!.send(utf8.encode(msg), InternetAddress("255.255.255.255"), port);
      print('[UDP] Broadcasted status message');
    } catch (e) {
      print('[UDP ERROR] $e');
    }
  }

  void stop() {
    _socket?.close();
    _socket = null;
  }
}
