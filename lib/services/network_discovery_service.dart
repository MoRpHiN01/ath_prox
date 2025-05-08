import 'dart:async';
import 'dart:convert';
import 'dart:io';

class NetworkDiscoveryService {
  static const int port = 9999;
  RawDatagramSocket? _socket;
  String? _instanceId;
  void Function(String id, String name, String? ip)? _onFound;

  void start(String displayName, void Function(String id, String name, String? ip) onFound, String instanceId) async {
    _instanceId = instanceId;
    _onFound = onFound;
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
      _socket!.broadcastEnabled = true;
      _socket!.listen(_handleSocketEvent);
      print('[NetworkDiscoveryService] Listening on port $port');
    } catch (e) {
      print('[NetworkDiscoveryService] Failed to bind socket: $e');
    }
  }

  void _handleSocketEvent(RawSocketEvent event) {
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
        if (user != null) _onFound?.call(id, user, dg.address.address);
      } catch (e) {
        print('[NetworkDiscoveryService] Error parsing UDP packet: $e');
      }
    }
  }

  Future<bool> sendInvite({
    required String toId,
    required String fromName,
    required String instanceId,
    String? targetIp,
  }) async {
    try {
      final msg = jsonEncode({
        'proto': 'ath-prox-v1',
        'type': 'invite',
        'from': fromName,
        'instanceId': instanceId,
        'targetId': toId,
      });

      final address = targetIp != null ? InternetAddress(targetIp) : InternetAddress('255.255.255.255');
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      socket.send(utf8.encode(msg), address, port);
      socket.close();
      print('[NetworkDiscoveryService] Invite sent to $toId');
      return true;
    } catch (e) {
      print('[NetworkDiscoveryService] Failed to send invite: $e');
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
      print('[NetworkDiscoveryService] Status broadcasted');
    } catch (e) {
      print('[NetworkDiscoveryService] Failed to broadcast status: $e');
    }
  }

  void dispose() {
    _socket?.close();
    _socket = null;
    print('[NetworkDiscoveryService] Socket closed');
  }
}
