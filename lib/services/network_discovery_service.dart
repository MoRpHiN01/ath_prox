// lib/services/network_discovery_service.dart

import 'dart:convert';
import 'dart:io';

class NetworkDiscoveryService {
  static const int port = 9999;
  RawDatagramSocket? _socket;

  void start(String displayName, void Function(String, String, String?) onFound) async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
      _socket!.broadcastEnabled = true;
      _socket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = _socket!.receive();
          if (dg == null) return;
          try {
            final map = jsonDecode(utf8.decode(dg.data)) as Map<String, dynamic>;
            if (map['proto'] != 'ath-prox-v1') return;
            final id = map['instanceId'] as String?;
            final user = map['user'] as String?;
            if (id != null && user != null) {
              onFound(id, user, dg.address.address);
            }
          } catch (e) {
            print('[UDP PARSE ERROR] $e');
          }
        }
      });

      // Broadcast status
      broadcastStatus(displayName, const Uuid().v4());
    } catch (e) {
      print('[UDP ERROR] $e');
    }
  }

  void broadcastStatus(String name, String id) async {
    final msg = jsonEncode({
      'proto': 'ath-prox-v1',
      'type': 'status',
      'user': name,
      'instanceId': id,
    });
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.send(utf8.encode(msg), InternetAddress('255.255.255.255'), port);
    socket.close();
    print('[UDP] Broadcasted status message');
  }

  Future<bool> sendInvite({
    required String from,
    required String fromId,
    required String targetId,
    required String? targetIp,
  }) async {
    if (targetIp == null) return false;
    try {
      final msg = jsonEncode({
        'proto': 'ath-prox-v1',
        'type': 'invite',
        'from': from,
        'instanceId': fromId,
        'targetId': targetId,
      });
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.send(utf8.encode(msg), InternetAddress(targetIp), port);
      socket.close();
      print('[INVITE] Sent over WiFi to $from');
      return true;
    } catch (e) {
      print('[INVITE ERROR] $e');
      return false;
    }
  }

  void stop() {
    _socket?.close();
    _socket = null;
  }
}
