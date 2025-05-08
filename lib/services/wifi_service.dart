import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../models/peer.dart';

class WifiService {
  static const int port = 4040;
  RawDatagramSocket? _socket;
  final void Function(Peer) onPeerDiscovered;

  WifiService({required this.onPeerDiscovered});

  Future<void> startBroadcast(Peer self) async {
    final packet = self.toUdpPacket();
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    Timer.periodic(Duration(seconds: 5), (timer) {
      _socket?.send(packet, InternetAddress('255.255.255.255'), port);
    });

    _socket?.listen((event) {
      if (event == RawSocketEvent.read) {
        final dg = _socket?.receive();
        if (dg != null && dg.data.isNotEmpty) {
          final peer = Peer.fromUdpPacket(dg.data);
          if (peer != null && peer.instanceId != self.instanceId) {
            onPeerDiscovered(peer);
          }
        }
      }
    });
  }

  Future<void> stop() async {
    _socket?.close();
  }
}