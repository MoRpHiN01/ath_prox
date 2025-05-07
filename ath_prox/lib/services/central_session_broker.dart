import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session.dart'; // ✅ updated import

class CentralSessionBroker {
  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();
  List<Session> _activeSessions = [];

  List<Session> get activeSessions => List.unmodifiable(_activeSessions);

  Future<void> init() async {
    await _loadSessionsFromStorage();
  }

  void startAdvertising(String userName) {
    final data = jsonEncode({
      'type': 'invite',
      'user': userName,
      'timestamp': DateTime.now().toIso8601String(),
    });

    _blePeripheral.start(
      advertiseData: AdvertiseData(
        manufacturerId: 0xFF,
        manufacturerData: Uint8List.fromList(utf8.encode(data)),
      ),
    );
  }

  void stopAdvertising() {
    _blePeripheral.stop();
  }

  void registerIncomingInvite(String dataString) {
    final decoded = jsonDecode(dataString);
    if (decoded['type'] == 'invite') {
      final session = Session(
        deviceId: decoded['deviceId'] ?? 'N/A',
        deviceName: decoded['user'] ?? 'Unknown',
        startTime: DateTime.now(),
        status: SessionStatus.pending,
      );
      _activeSessions.add(session);
      _saveSessionsToStorage();
    }
  }

  Future<void> _saveSessionsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _activeSessions.map((s) => jsonEncode(s.toMap())).toList();
    prefs.setStringList('activeSessions', encoded);
  }

  Future<void> _loadSessionsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('activeSessions') ?? [];
    _activeSessions = stored.map((jsonStr) {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Session.fromMap(map);
    }).toList();
  }
}
