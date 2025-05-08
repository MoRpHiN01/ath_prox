// lib/services/network_discovery_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:logger/logger.dart';

import '../models/peer.dart';
import 'ble_service.dart';

/// UDP peer discovery + presence & invite broadcasting.
class NetworkDiscoveryService {
  static const int port = 9999;
  final void Function(Peer) onPeerFound;
  RawDatagramSocket? _socket;

  NetworkDiscoveryService({required this.onPeerFound});

  /// Bind to UDP port (with reusePort fallback on Android 11).
  Future<void> start() async {
    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        port,
        reuseAddress: true,
        reusePort: true,
      );
    } catch (_) {
      Logger().w('reusePort not supported, retrying without it');
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        port,
        reuseAddress: true,
      );
    }
    _socket!
      ..broadcastEnabled = true
      ..listen(_onData, onError: (e) => Logger().e('UDP error: $e'));
    Logger().i('UDP listening on port $port');
  }

  void _onData(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final dg = _socket!.receive();
    if (dg == null) return;
    final peer = Peer.fromUdpPacket(dg.data);
    if (peer != null && peer.instanceId != BleService.instanceId) {
      onPeerFound(peer);
    }
  }

  /// Broadcast presence or invite.
  Future<void> sendInvite(Peer me) async {
    final packet = me.toUdpPacket();
    _socket?.send(packet, InternetAddress('255.255.255.255'), port);
    Logger().i('UDP ${me.status == 'pending' ? 'invite' : 'presence'}: ${me.displayName}');
  }

  /// Clean up socket.
  void dispose() {
    _socket?.close();
    _socket = null;
  }
}
