// lib/services/network_discovery_service.dart

import 'dart:convert';
import 'dart:io';

class NetworkDiscoveryService {
  static const int port = 9999;
  RawDatagramSocket? _socket;
  String? _localName;
  String? _instanceId;

  void start(String name, String instanceId, {required void Function(String, String, String) onFound}) async {
    _localName = name;
    _instanceId = instanceId;
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
      _socket!.broadcastEnabled = true;
      _socket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = _socket!.receive();
          if (dg == null) return;
          try {
            final data = jsonDecode(utf8.decode(dg.data)) as Map<String, dynamic>;
            if (data['proto'] != 'ath-prox-v1' || data['instanceId'] == _instanceId) return;
            if (data['type'] == 'status' && data['user'] != null) {
              onFound(data['instanceId'], data['user'], dg.address.address);
            }
          } catch (e) {
            print('[UDP PARSE ERROR] $e');
          }
        }
      });
    } catch (e) {
      print('[UDP SOCKET ERROR] $e');
    }
  }

  void stop() {
    _socket?.close();
    _socket = null;
  }

  void broadcastStatus(String name, String instanceId) async {
    final message = {
      'proto': 'ath-prox-v1',
      'type': 'status',
      'user': name,
      'instanceId': instanceId,
    };
    final data = utf8.encode(jsonEncode(message));
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;
    socket.send(data, InternetAddress("255.255.255.255"), port);
    socket.close();
    print('[UDP] Broadcasted status message');
  }

  Future<bool> sendInvite({
    required String toIp,
    required String fromName,
    required String fromId,
    required String targetId,
  }) async {
    try {
      final message = {
        'proto': 'ath-prox-v1',
        'type': 'invite',
        'from': fromName,
        'instanceId': fromId,
        'targetId': targetId,
      };
      final data = utf8.encode(jsonEncode(message));
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.send(data, InternetAddress(toIp), port);
      socket.close();
      print('[INVITE] Sent over WiFi to $toIp');
      return true;
    } catch (e) {
      print('[INVITE ERROR] $e');
      return false;
    }
  }
}
