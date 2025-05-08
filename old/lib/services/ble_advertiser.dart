// lib/services/ble_advertiser.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

import '../services/ble_service.dart';
import '../services/user_model.dart';

/// BLE peripheral advertising of custom payload every interval.
class BleAdvertiser {
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();
  final UserModel _userModel;
  Timer? _timer;

  BleAdvertiser(this._userModel);

  /// Start advertising every [interval] seconds (default 10s).
  void start({Duration interval = const Duration(seconds: 10)}) {
    _timer = Timer.periodic(interval, (_) => _broadcast());
    _broadcast();
  }

  /// Stop advertising.
  void stop() {
    _timer?.cancel();
    _peripheral.stop();
  }

  void _broadcast() {
    final payloadMap = {
      'instanceId': BleService.instanceId,
      'displayName': _userModel.displayName,
      'status': 'available',
    };
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payloadMap)));

    _peripheral.start(
      advertiseData: AdvertiseData(
        manufacturerId: 0xFFFF,
        manufacturerData: bytes,
      ),
    );
  }
}
