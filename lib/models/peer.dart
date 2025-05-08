import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Peer {
  static final String protoKey = 'ath-prox-v1';

  final String instanceId;
  final String displayName;
  final String status;

  Peer({
    required this.instanceId,
    required this.displayName,
    required this.status,
  });

  Peer copyWith({String? displayName, String? status}) {
    return Peer(
      instanceId: instanceId,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
    );
  }

  static Peer? fromAdvertisement(ScanResult result) {
    final mfg = result.advertisementData.manufacturerData[0xFFFF];
    if (mfg == null) return null;

    try {
      final map = jsonDecode(utf8.decode(Uint8List.fromList(mfg))) as Map;
      final id = map['instanceId'] as String;
      var name = (map['displayName'] as String?)?.trim() ?? '';
      if (name.isEmpty) {
        name = result.device.name.isNotEmpty
            ? result.device.name
            : 'Unknown Device';
      }
      final status = (map['status'] as String?)?.trim() ?? 'available';
      return Peer(instanceId: id, displayName: name, status: status);
    } catch (_) {
      return null;
    }
  }

  static Peer? fromUdpPacket(Uint8List bytes) {
    try {
      final map = jsonDecode(utf8.decode(bytes)) as Map;
      final id = map['instanceId'] as String;
      var name = (map['displayName'] as String?)?.trim() ?? 'Unknown Device';
      final status = (map['status'] as String?)?.trim() ?? 'available';
      return Peer(instanceId: id, displayName: name, status: status);
    } catch (_) {
      return null;
    }
  }

  Uint8List toUdpPacket() {
    final jsonStr = jsonEncode({
      'instanceId': instanceId,
      'displayName': displayName,
      'status': status,
    });
    return Uint8List.fromList(utf8.encode(jsonStr));
  }
}