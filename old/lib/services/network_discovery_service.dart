// lib/services/network_discovery_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import '../models/peer.dart';

class NetworkDiscoveryService {
  static const int _port = 9999;
  static final Logger _logger = Logger();

  RawDatagramSocket? _socket;
  final String instanceId;
  final String displayName;
  final String status;
  final void Function(Peer) onPeerDiscovered;

  NetworkDiscoveryService({
    required this.instanceId,
    required this.displayName,
    required this.status,
    required this.onPeerDiscovered,
  });

  Future<void> start() async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _port);
      _socket?.broadcastEnabled = true;
      _socket?.listen(_handlePacket);
      _logger.i('UDP listening on port $_port');
    } catch (e) {
      _logger.e('Failed to bind UDP socket: $e');
    }
  }

  void _handlePacket(RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      final datagram = _socket?.receive();
      if (datagram != null) {
        final peer = Peer.fromUdpPacket(datagram.data);
        if (peer != null && peer.instanceId != instanceId) {
          onPeerDiscovered(peer);
        }
      }
    }
  }

  Future<void> broadcastStatus() async {
    final map = {
      'instanceId': instanceId,
      'displayName': displayName,
      'status': status,
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(map)));

    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          final bcast = addr.rawAddress;
          if (bcast.length == 4) {
            final broadcastAddress = InternetAddress.fromRawAddress([
              bcast[0],
              bcast[1],
              bcast[2],
              255
            ]);
            _socket?.send(bytes, broadcastAddress, _port);
          }
        }
      }
    } catch (e) {
      _logger.e('Failed to broadcast UDP status: $e');
    }
  }

  Future<void> dispose() async {
    _socket?.close();
  }
}
