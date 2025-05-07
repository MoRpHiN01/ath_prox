// network_discovery_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

typedef PeerCallback = void Function(String ip, String displayName);

class NetworkDiscoveryService {
  static const int _port = 4567;
  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  PeerCallback? onPeerFound;

  /// Call this once at startup to bind the socket and start both
  /// broadcasting our info and listening for others.
  Future<void> start(String displayName) async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _port);
    _socket!.broadcastEnabled = true;
    _socket!.listen(_handleDatagram);

    // every 5 seconds, send out our presence
    _broadcastTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final msg = jsonEncode({
        'ip': _socket!.address.address,
        'user': displayName,
      });
      final data = utf8.encode(msg);
      _socket!.send(
        data,
        InternetAddress('255.255.255.255'),
        _port,
      );
    });
  }

  void _handleDatagram(RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      final dg = _socket!.receive();
      if (dg == null) return;

      try {
        final msg = utf8.decode(dg.data);
        final map = jsonDecode(msg) as Map<String, dynamic>;
        final peerIp = dg.address.address;
        final peerName = map['user'] as String? ?? 'Unknown';
        if (onPeerFound != null) {
          onPeerFound!(peerIp, peerName);
        }
      } catch (_) {
        // ignore bad packets
      }
    }
  }

  /// Clean up
  void stop() {
    _broadcastTimer?.cancel();
    _socket?.close();
    _socket = null;
  }
}
