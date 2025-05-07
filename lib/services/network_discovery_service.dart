// lib/services/network_discovery_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';

/// Simple UDP broadcast discovery service (IPv4) with status broadcasts
class NetworkDiscoveryService {
  static const int port = 9999;
  late RawDatagramSocket _socket;
  late Timer _timer;
  final String _instanceId = const Uuid().v4();
  late String _userName;

  /// Fired when a peer is discovered: IP address, display name, and senderId
  void Function(String ip, String name, String senderId) onPeerFound =
    (ip, name, senderId) {};

  /// Start broadcasting and listening
  Future<void> start(String userName) async {
    _userName = userName;
    _socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      port,
      reuseAddress: true,
      reusePort: true,
    );
    _socket.broadcastEnabled = true;
    _socket.listen(_handleSocketEvent);

    // Broadcast status every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      final payload = jsonEncode({
        'proto': 'ath-prox-v1',
        'type': 'status',
        'user': _userName,
        'instanceId': _instanceId,
      });
      _socket.send(
        utf8.encode(payload),
        InternetAddress('255.255.255.255'),
        port,
      );
    });
  }

  void _handleSocketEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final datagram = _socket.receive();
    if (datagram == null) return;
    try {
      final msg = utf8.decode(datagram.data);
      final map = jsonDecode(msg) as Map<String, dynamic>;
      if (map['proto'] != 'ath-prox-v1') return;
      final senderId = map['instanceId'] as String?;
      final name = map['user'] as String?;
      final type = map['type'] as String?;
      final ip = datagram.address.address;
      if (senderId != null && name != null && senderId != _instanceId) {
        if (type == 'status' || type == 'invite') {
          onPeerFound(ip, name, senderId);
        }
      }
    } catch (_) {
      // ignore invalid payloads
    }
  }

  /// Stop broadcasting and listening
  void stop() {
    _timer.cancel();
    _socket.close();
  }
}
