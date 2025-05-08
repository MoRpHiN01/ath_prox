// lib/models/peer.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Represents a discovered peer in the ATH Proximity protocol.
class Peer {
  static const String protoKey = 'ath-prox-v1';

  final String instanceId;
  final String displayName;
  final String status; // 'available', 'pending', 'accepted', 'ended'

  Peer({
    required this.instanceId,
    required this.displayName,
    required this.status,
  });

  /// Clone with optional overrides.
  Peer copyWith({String? displayName, String? status}) {
    return Peer(
      instanceId: instanceId,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
    );
  }

  /// Parse BLE manufacturer data into Peer.
  static Peer? fromAdvertisement(ScanResult result) {
    final data = result.advertisementData.manufacturerData[0xFFFF];
    if (data == null) return null;

    try {
      final decoded = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;

      final id = decoded['instanceId']?.toString().trim();
      if (id == null || id.isEmpty) return null;

      String name = decoded['displayName']?.toString().trim() ?? '';
      if (name.isEmpty) {
        name = result.device.name.isNotEmpty
            ? result.device.name
            : result.device.id.id;
      }

      final status = decoded['status']?.toString().trim() ?? 'available';

      return Peer(instanceId: id, displayName: name, status: status);
    } catch (_) {
      return null;
    }
  }

  /// Parse UDP packet into Peer.
  static Peer? fromUdpPacket(Uint8List bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

      final id = decoded['instanceId']?.toString().trim();
      if (id == null || id.isEmpty) return null;

      String name = decoded['displayName']?.toString().trim() ?? 'Unknown Device';
      final status = decoded['status']?.toString().trim() ?? 'available';

      return Peer(instanceId: id, displayName: name, status: status);
    } catch (_) {
      return null;
    }
  }

  /// Convert to UDP packet.
  Uint8List toUdpPacket() {
    final map = {
      'instanceId': instanceId,
      'displayName': displayName,
      'status': status,
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(map)));
  }
}
