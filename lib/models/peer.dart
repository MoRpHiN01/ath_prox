// lib/models/peer.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Represents a discovered peer in our protocol.
class Peer {
  static final String protoKey = 'ath-prox-v1';

  final String instanceId;
  final String displayName;
  final String status; // e.g. 'available', 'pending', 'accepted', 'ended'

  Peer({
    required this.instanceId,
    required this.displayName,
    required this.status,
  });

  /// Create a modified clone.
  Peer copyWith({String? displayName, String? status}) {
    return Peer(
      instanceId: instanceId,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
    );
  }

  /// Parse a BLE ScanResult from our manufacturerData payload (0xFFFF).
  static Peer? fromAdvertisement(ScanResult result) {
    final mfg = result.advertisementData.manufacturerData[0xFFFF];
    if (mfg == null) return null;

    try {
      final map = jsonDecode(utf8.decode(Uint8List.fromList(mfg))) as Map;
      final id = map['instanceId'] as String;
      var name = (map['displayName'] as String).trim();
      if (name.isEmpty) {
        name = result.device.name.isNotEmpty
            ? result.device.name
            : 'Unknown Device';
      }
      final status = (map['status'] as String).trim().isNotEmpty
          ? map['status'] as String
          : 'available';
      return Peer(instanceId: id, displayName: name, status: status);
    } catch (_) {
      return null;
    }
  }

  /// Parse our UDP JSON packet.
  static Peer? fromUdpPacket(Uint8List bytes) {
    try {
      final map = jsonDecode(utf8.decode(bytes)) as Map;
      final id = map['instanceId'] as String;
      var name = (map['displayName'] as String).trim();
      if (name.isEmpty) name = 'Unknown Device';
      final status = (map['status'] as String).trim().isNotEmpty
          ? map['status'] as String
          : 'available';
      return Peer(instanceId: id, displayName: name, status: status);
    } catch (_) {
      return null;
    }
  }

  /// Serialize to UDP JSON packet.
  Uint8List toUdpPacket() {
    final jsonStr = jsonEncode({
      'instanceId': instanceId,
      'displayName': displayName,
      'status': status,
    });
    return Uint8List.fromList(utf8.encode(jsonStr));
  }
}
