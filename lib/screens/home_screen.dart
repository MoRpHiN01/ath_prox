// lib/screens/home_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../models/session.dart';
import '../services/ble_service.dart';
import '../services/nfc_service.dart';
import '../services/wifi_service.dart';
import '../services/session_sync_service.dart';
import '../widgets/session_invite_bubble.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BleService _bleService = BleService();
  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();
  final WifiService _wifiService = WifiService();
  final NfcService _nfcService = NfcService();

  final List<Session> activeSessions = [];
  final List<Session> completedSessions = [];
  final Map<String, String> deviceStatuses = {};
  final Map<String, DateTime> sessionStartTimes = {};

  bool _isAdvertising = false;
  late UserModel user;

  @override
  void initState() {
    super.initState();
    _bleService.startScan();
    _nfcService.startSession(_handleNfcInvite);
  }

  @override
  void dispose() {
    _bleService.stopScan();
    _blePeripheral.stop();
    _nfcService.stopSession();
    super.dispose();
  }

  void _toggleAdvertising() async {
    if (_isAdvertising) {
      await _blePeripheral.stop();
      setState(() => _isAdvertising = false);
      Fluttertoast.showToast(msg: "Stopped BLE Advertising");
    } else {
      final payload = jsonEncode({
        "user": user.displayName,
        "status": "available",
        "ssid": await _wifiService.getSSID(),
        "ip": await _wifiService.getCurrentIP(),
      });

      await _blePeripheral.start(
        advertiseData: AdvertiseData(
          manufacturerId: 0xFF,
          manufacturerData: Uint8List.fromList(utf8.encode(payload)),
        ),
      );

      setState(() => _isAdvertising = true);
      Fluttertoast.showToast(msg: "Started BLE Advertising");
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
      deviceStatuses[deviceId] = accepted ? "connected" : "declined";
      if (accepted) {
        activeSessions.add(session);
        sessionStartTimes[deviceId] = now;
      } else {
        completedSessions.add(session);
      }
    });

    SessionSyncService.syncSessions([session]);
    Fluttertoast.showToast(
        msg: accepted ? "Session started with $displayName" : "$displayName declined");
  }

  void _showInviteBubble(BuildContext context, ScanResult result, String displayName) {
    final deviceId = result.device.remoteId.str;

    if (deviceStatuses[deviceId] == "pending" || deviceStatuses[deviceId] == "connected") return;
    setState(() => deviceStatuses[deviceId] = "pending");

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

  void _handleNfcInvite(String peerId, String peerName) {
    if (deviceStatuses.containsKey(peerId)) return;

final simulatedResult = ScanResult(
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

    _showInviteBubble(context, simulatedResult, peerName);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "connected":
        return Colors.blue;
      case "pending":
        return Colors.amber;
      case "declined":
        return Colors.red;
      case "lost":
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
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundImage: user.profileImagePath.isNotEmpty
                  ? Image.asset(user.profileImagePath).image
                  : const AssetImage('assets/images/logo.png'),
            ),
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user.displayName),
              accountEmail: Text(user.email ?? 'No email set'),
              currentAccountPicture: CircleAvatar(
                backgroundImage: user.profileImagePath.isNotEmpty
                    ? Image.asset(user.profileImagePath).image
                    : const AssetImage('assets/images/logo.png'),
              ),
            ),
            ListTile(
              title: const Text('Home'),
              onTap: () => Navigator.pushReplacementNamed(context, '/'),
            ),
            ListTile(
              title: const Text('Profile'),
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
            ListTile(
              title: const Text('Settings'),
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
            ListTile(
              title: const Text('Support'),
              onTap: () => Navigator.pushNamed(context, '/support'),
            ),
            ListTile(
              title: const Text('Reports'),
              onTap: () => Navigator.pushNamed(context, '/reports'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text("About"),
              onTap: () => Navigator.pushNamed(context, '/about'),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _toggleAdvertising,
            child: Text(_isAdvertising ? 'Stop Advertising' : 'Start Advertising'),
          ),
          Expanded(
            child: StreamBuilder<List<ScanResult>>(
              stream: _bleService.scanResults,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final results = snapshot.data!;
                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final result = results[index];
                    final deviceId = result.device.remoteId.str;
                    final displayName = _bleService.extractDisplayName(result);
                    final status = _bleService.extractStatus(result);
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
                          if (status == "connected" && startTime != null)
                            StreamBuilder(
                              stream: Stream.periodic(const Duration(seconds: 1)),
                              builder: (context, snapshot) {
                                final elapsed = DateTime.now().difference(startTime);
                                return Text('Timer: ${_formatDuration(elapsed)}');
                              },
                            )
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          if (status == "connected") {
                            setState(() {
                              deviceStatuses[deviceId] = "available";
                              sessionStartTimes.remove(deviceId);
                            });
                            Fluttertoast.showToast(msg: "Session ended with $displayName");
                          } else {
                            _showInviteBubble(context, result, displayName);
                          }
                        },
                        child: Text(status == "connected" ? "End Session" : "Invite"),
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
