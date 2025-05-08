// lib/services/wifi_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';
import '../models/peer.dart';

class WifiService {
  static final instanceId = const Uuid().v4();
  static const int port = 9999;
  static const Duration broadcastInterval = Duration(seconds: 5);

  final void Function(Peer) onPeerDiscovered;
  final void Function(Object)? onError;

  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;

  WifiService({
    required this.onPeerDiscovered,
    this.onError,
  });

  Future<void> start() async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port, reuseAddress: true);
      _socket?.broadcastEnabled = true;

      _socket?.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = _socket?.receive();
          if (dg != null) {
            final peer = Peer.fromUdpPacket(dg.data);
            if (peer != null && peer.instanceId != instanceId) {
              onPeerDiscovered(peer);
            }
          }
        }
      });

      _broadcastTimer = Timer.periodic(broadcastInterval, (_) => _broadcastPresence());
    } catch (e) {
      onError?.call(e);
    }
  }

  void _broadcastPresence() {
    final peer = Peer(
      instanceId: instanceId,
      displayName: Platform.localHostname,
      status: 'available',
    );
    final data = peer.toUdpPacket();

    _socket?.send(data, InternetAddress("255.255.255.255"), port);
  }

  void sendInvite(String displayName) {
    final packet = jsonEncode({
      'instanceId': instanceId,
      'displayName': displayName,
      'status': 'invite',
    });
    _socket?.send(Uint8List.fromList(utf8.encode(packet)), InternetAddress("255.255.255.255"), port);
  }

  Future<void> dispose() async {
    _broadcastTimer?.cancel();
    _socket?.close();
    _socket = null;
  }
}
