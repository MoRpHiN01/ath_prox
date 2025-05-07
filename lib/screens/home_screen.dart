// lib/screens/home_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_background_service/flutter_background_service.dart';

import '../widgets/app_drawer.dart';
import '../widgets/session_invite_bubble.dart';
import '../models/user_model.dart';
import '../models/session.dart';
import '../services/ble_service.dart';
import '../services/nfc_service.dart';
import '../services/wifi_service.dart';
import '../services/session_sync_service.dart';
import '../services/network_discovery_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BleService _bleService = BleService();
  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();
  final WifiService _wifiService = WifiService();
  final NfcService _nfcService = NfcService();
  final NetworkDiscoveryService _netDisc = NetworkDiscoveryService();

  final Map<String, String> deviceStatuses = {};
  final Map<String, DateTime> sessionStartTimes = {};
  bool _isAdvertising = false;
  late UserModel user;
  bool _networkStarted = false;

  @override
  void initState() {
    super.initState();
    _ensurePermissions();
    _nfcService.startSession(_handleNfcInvite);

    // Listen for Wi-Fi invites
    final service = FlutterBackgroundService();
    service.on('wifiInvite').listen((event) {
      final data = event as Map<String, dynamic>?;
      final from = data?['from'] as String?;
      final sessionId = data?['sessionId'] as String?;
      if (from != null && sessionId != null) {
        _showWifiInvite(from, sessionId);
      }
    });
  }

  /// Request required permissions before starting BLE scan
  Future<void> _ensurePermissions() async {
    if (Platform.isAndroid) {
      final perms = [
        Permission.locationWhenInUse,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
      ];
      for (final perm in perms) {
        if (!await perm.isGranted) {
          final status = await perm.request();
          if (!status.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permissions are required for BLE scanning.'),
              ),
            );
            return;
          }
        }
      }
    }
    _bleService.startScan();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_networkStarted) {
      user = Provider.of<UserModel>(context, listen: false);
      _netDisc.onPeerFound = (ip, name) {
        _showWifiInvite(name, ip);
      };
      _netDisc.start(user.displayName);
      _networkStarted = true;
    }
  }

  @override
  void dispose() {
    _bleService.stopScan();
    _blePeripheral.stop();
    _nfcService.stopSession();
    _netDisc.stop();
    super.dispose();
  }

  Future<void> _toggleAdvertising() async {
    if (_isAdvertising) {
      await _blePeripheral.stop();
      setState(() => _isAdvertising = false);
      Fluttertoast.showToast(msg: 'Stopped BLE Advertising');
    } else {
      final payload = jsonEncode({
        'user': user.displayName,
        'status': 'available',
        'ssid': await _wifiService.getSSID(),
        'ip': await _wifiService.getCurrentIP(),
      });
      await _blePeripheral.start(
        advertiseData: AdvertiseData(
          manufacturerId: 0xFF,
          manufacturerData: Uint8List.fromList(utf8.encode(payload)),
        ),
      );
      setState(() => _isAdvertising = true);
      Fluttertoast.showToast(msg: 'Started BLE Advertising');
    }
  }

  void _handleInviteResponse(String deviceId, String displayName, bool accepted) {
    final now = DateTime.now();
    final session = Session(
      sessionId: now.millisecondsSinceEpoch.toString(),
      deviceId: deviceId,
      deviceName: displayName,
      startTime: now,
      status: accepted ? SessionStatus.accepted : SessionStatus.declined,
    );
    setState(() {
      deviceStatuses[deviceId] = accepted ? 'connected' : 'declined';
      if (accepted) sessionStartTimes[deviceId] = now;
    });
    SessionSyncService.syncSessions([session]);
    Fluttertoast.showToast(
      msg: accepted
          ? 'Session started with $displayName'
          : '$displayName declined',
    );
  }

  void _showInviteBubble(ScanResult result, String displayName) {
    final deviceId = result.device.remoteId.id;
    if (deviceStatuses[deviceId] == 'pending' ||
        deviceStatuses[deviceId] == 'connected') return;
    setState(() => deviceStatuses[deviceId] = 'pending');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SessionInviteBubble(
        deviceName: displayName,
        onAccept: () => _handleInviteResponse(deviceId, displayName, true),
        onDecline: () => _handleInviteResponse(deviceId, displayName, false),
      ),
    );
  }

  void _showWifiInvite(String displayName, String sessionId) {
    if (deviceStatuses.containsKey(sessionId)) return;
    setState(() => deviceStatuses[sessionId] = 'pending');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SessionInviteBubble(
        deviceName: displayName,
        onAccept: () {
          Navigator.of(context).pop();
          _handleInviteResponse(sessionId, displayName, true);
        },
        onDecline: () {
          Navigator.of(context).pop();
          _handleInviteResponse(sessionId, displayName, false);
        },
      ),
    );
  }

  void _handleNfcInvite(String peerId, String peerName) {
    if (deviceStatuses.containsKey(peerId)) return;
    final simulated = ScanResult(
      device: BluetoothDevice(remoteId: DeviceIdentifier(peerId)),
      advertisementData: AdvertisementData(
        advName: peerName,
        txPowerLevel: -10,
        appearance: 0,
        connectable: true,
        manufacturerData: {},
        serviceData: {},
        serviceUuids: [],
      ),
      rssi: -50,
      timeStamp: DateTime.now(),
    );
    _showInviteBubble(simulated, peerName);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'connected':
        return Colors.blue;
      case 'pending':
        return Colors.amber;
      case 'declined':
        return Colors.red;
      case 'lost':
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '${d.inHours}:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    user = Provider.of<UserModel>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${user.displayName}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              backgroundImage: user.profileImagePath.isNotEmpty
                  ? Image.asset(user.profileImagePath).image
                  : const AssetImage('assets/images/logo.png'),
            ),
          ),
        ],
      ),
      drawer: AppDrawer(onNavigate: (route) {
        Navigator.of(context).pop();
        if (ModalRoute.of(context)!.settings.name != route) {
          Navigator.of(context).pushReplacementNamed(route);
        }
      }),
      body: Column(
        children: [
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _toggleAdvertising,
            child: Text(
              _isAdvertising ? 'Stop Advertising' : 'Start Advertising',
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ScanResult>>(
              stream: _bleService.scanResults,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final results = snapshot.data!;
                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final result = results[index];
                    final deviceId = result.device.remoteId.id;
                    String displayName;
                    String status;
                    try {
                      final data = result.advertisementData.manufacturerData.values.first;
                      final jsonStr = utf8.decode(data);
                      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
                      displayName = map['user'] as String? ?? result.device.name;
                      status = map['status'] as String? ?? 'unknown';
                    } catch (_) {
                      displayName = result.device.name.isNotEmpty
                          ? result.device.name
                          : deviceId;
                      status = 'unknown';
                    }
                    final startTime = sessionStartTimes[deviceId];
                    deviceStatuses[deviceId] = status;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(status),
                        radius: 8,
                      ),
                      title: Text(displayName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$deviceId\nStatus: $status'),
                          if (status == 'connected' && startTime != null)
                            StreamBuilder(
                              stream: Stream.periodic(const Duration(seconds: 1)),
                              builder: (_, __) {
                                final elapsed = DateTime.now().difference(startTime);
                                return Text('Timer: ${_formatDuration(elapsed)}');
                              },
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              if (status == 'connected') {
                                setState(() {
                                  deviceStatuses[deviceId] = 'available';
                                  sessionStartTimes.remove(deviceId);
                                });
                                Fluttertoast.showToast(msg: 'Session ended with $displayName');
                              } else {
                                _showInviteBubble(result, displayName);
                              }
                            },
                            child: Text(status == 'connected' ? 'End' : 'BLE Invite'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final ip = await _wifiService.getCurrentIP();
                              if (ip == null) {
                                Fluttertoast.showToast(msg: 'Not connected to Wi-Fi');
                                return;
                              }
                              final uri = Uri.parse('http://$ip:8080/invite');
                              try {
                                await http.post(
                                  uri,
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode({
                                    'from': user.displayName,
                                    'sessionId': DateTime.now().millisecondsSinceEpoch.toString(),
                                  }),
                                );
                                Fluttertoast.showToast(msg: 'Wi-Fi invite sent');
                              } catch (e) {
                                Fluttertoast.showToast(msg: 'Error sending Wi-Fi invite: $e');
                              }
                            },
                            child: const Text('Wi-Fi Invite'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
