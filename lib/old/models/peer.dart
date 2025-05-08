// lib/models/peer.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Represents a discovered peer device
class Peer {
  static const String protoKey = 'ath-prox-v1';

  final String instanceId;
  final String displayName;
  final String status;
  final String? ipAddress;
  final String? deviceType;
  final String? transport; // 'ble', 'wifi', 'nfc'

  Peer({
    required this.instanceId,
    required this.displayName,
    required this.status,
    this.ipAddress,
    this.deviceType,
    this.transport,
  });

  /// Create a copy with optional overrides
  Peer copyWith({
    String? displayName,
    String? status,
    String? ipAddress,
    String? deviceType,
    String? transport,
  }) {
    return Peer(
      instanceId: instanceId,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
      ipAddress: ipAddress ?? this.ipAddress,
      deviceType: deviceType ?? this.deviceType,
      transport: transport ?? this.transport,
    );
  }

  /// Deserialize from BLE advertisement payload (manufacturerData)
  static Peer? fromAdvertisement(ScanResult result) {
    final raw = result.advertisementData.manufacturerData[0xFFFF];
    if (raw == null) return null;

    try {
      final map = jsonDecode(utf8.decode(Uint8List.fromList(raw))) as Map<String, dynamic>;
      final id = map['instanceId'] ?? '';
      final display = (map['displayName'] ?? '').toString().trim();
      final status = (map['status'] ?? 'available').toString().trim();
      final fallbackName = result.device.name.isNotEmpty ? result.device.name : result.device.id.id;

      return Peer(
        instanceId: id,
        displayName: display.isNotEmpty ? display : fallbackName,
        status: status,
        deviceType: 'BLE',
        transport: 'ble',
      );
    } catch (e) {
      return null;
    }
  }

  /// Deserialize from UDP packet (Wi-Fi)
  static Peer? fromUdpPacket(Uint8List data) {
    try {
      final jsonStr = utf8.decode(data);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;

      final id = map['instanceId'] ?? '';
      final display = (map['displayName'] ?? '').toString().trim();
      final status = (map['status'] ?? 'available').toString().trim();
      final fallbackName = map['deviceName'] ?? map['ipAddress'] ?? 'Unknown';

      return Peer(
        instanceId: id,
        displayName: display.isNotEmpty ? display : fallbackName,
        status: status,
        ipAddress: map['ipAddress'],
        deviceType: map['deviceType'] ?? 'Wi-Fi',
        transport: 'wifi',
      );
    } catch (e) {
      return null;
    }
  }

  /// Deserialize from NFC payload
  static Peer? fromNfcPayload(String payload) {
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;

      final id = map['instanceId'] ?? '';
      final display = (map['displayName'] ?? '').toString().trim();
      final status = (map['status'] ?? 'available').toString().trim();

      return Peer(
        instanceId: id,
        displayName: display.isNotEmpty ? display : 'NFC Peer',
        status: status,
        deviceType: map['deviceType'] ?? 'NFC',
        transport: 'nfc',
      );
    } catch (e) {
      return null;
    }
  }

  /// Convert to BLE-compatible advertising packet
  Uint8List toBleAdvertisement() {
    final payload = {
      'instanceId': instanceId,
      'displayName': displayName,
      'status': status,
    };

    return Uint8List.fromList(utf8.encode(jsonEncode(payload)));
  }

  /// Convert to UDP packet
  Uint8List toUdpPacket() {
    final map = {
      'instanceId': instanceId,
      'displayName': displayName,
      'status': status,
      'ipAddress': ipAddress ?? '',
      'deviceType': deviceType ?? 'Unknown',
    };

    return Uint8List.fromList(utf8.encode(jsonEncode(map)));
  }

  /// Convert to NFC payload string
  String toNfcPayload() {
    final map = {
      'instanceId': instanceId,
      'displayName': displayName,
      'status': status,
      'deviceType': deviceType ?? 'NFC',
    };

    return jsonEncode(map);
  }
}
