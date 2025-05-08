// lib/services/network_discovery_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

class NetworkDiscoveryService {
  static const int port = 9999;
  RawDatagramSocket? _socket;
  String? _instanceId;

  void start(String displayName, void Function(String id, String name, String? ip) onFound, String instanceId) async {
    _instanceId = instanceId;
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    _socket!.broadcastEnabled = true;

    _socket!.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        final dg = _socket!.receive();
        if (dg == null) return;

        try {
          final msg = utf8.decode(dg.data);
          final map = jsonDecode(msg);

          if (map['proto'] != 'ath-prox-v1') return;
          final id = map['instanceId'] as String?;
          if (id == null || id == _instanceId) return;

          final user = map['user'] as String?;
          if (user != null) onFound(id, user, dg.address.address);

          if (map['type'] == 'invite' && map['targetId'] == _instanceId) {
            // handle invite delivery
          }
        } catch (e) {
          print('[UDP PARSE ERROR] $e');
        }
      }
    });
  }

  Future<bool> sendInvite({
    required String toId,
    required String fromName,
    required String fromId,
    String? targetIp,
  }) async {
    try {
      final msg = jsonEncode({
        'proto': 'ath-prox-v1',
        'type': 'invite',
        'from': fromName,
        'instanceId': fromId,
        'targetId': toId,
      });

      final address = targetIp != null ? InternetAddress(targetIp) : InternetAddress('255.255.255.255');
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      socket.send(utf8.encode(msg), address, port);
      socket.close();
      print('[INVITE] Sent over WiFi to $fromName');
      return true;
    } catch (e) {
      print('[INVITE ERROR] $e');
      return false;
    }
  }

  void broadcastStatus(String name, String instanceId) async {
    try {
      final msg = jsonEncode({
        'proto': 'ath-prox-v1',
        'type': 'status',
        'user': name,
        'instanceId': instanceId,
      });
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      socket.send(utf8.encode(msg), InternetAddress('255.255.255.255'), port);
      socket.close();
      print('[UDP] Broadcasted status message');
    } catch (e) {
      print('[UDP STATUS ERROR] $e');
    }
  }

  void dispose() {
    _socket?.close();
  }
}
