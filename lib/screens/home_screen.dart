// lib/screens/home_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:uuid/uuid.dart';

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
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _bleService = BleService();
  final _blePeripheral = FlutterBlePeripheral();
  final _wifiService = WifiService();
  final _nfcService = NfcService();
  final _netDisc = NetworkDiscoveryService();
  final _instanceId = const Uuid().v4();

  late UserModel _user;
  bool _isAdvertising = false;
  final Map<String, String> _deviceStatus = {};
  final Map<String, DateTime> _startTimes = {};

  late StreamSubscription<List<ScanResult>> _scanSub;
  late StreamSubscription _wifiInviteSub;

  @override
  void initState() {
    super.initState();

    // Always start scanning and NFC
    _bleService.startScan();
    _nfcService.startSession(_handleNfcInvite);

    // Subscribe to BLE scan results (no auto invites)
    _scanSub = _bleService.scanResults.listen((results) {
      setState(() {
        // just refresh UI
      });
    });

    // Start network discovery
    _netDisc.onPeerFound = (ip, name) => _showInvite(name, ip);
    // Delay obtaining user until build/didChangeDependencies

    // Listen for background Wi-Fi invites
    _wifiInviteSub = FlutterBackgroundService().on('wifiInvite').listen((event) {
      if (event is Map<String, dynamic>) {
        _showInvite(event['from'], event['sessionId'], senderId: event['instanceId']);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _user = Provider.of<UserModel>(context);
  }

  @override
  void dispose() {
    _bleService.stopScan();
    _blePeripheral.stop();
    _nfcService.stopSession();
    _netDisc.stop();
    _scanSub.cancel();
    _wifiInviteSub.cancel();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _deviceStatus.clear();
      _startTimes.clear();
    });
    _bleService.startScan();
    Fluttertoast.showToast(msg: 'Refreshing device list...');
  }

  Future<void> _toggleAdvertising() async {
    if (_isAdvertising) {
      await _blePeripheral.stop();
      setState(() => _isAdvertising = false);
      Fluttertoast.showToast(msg: 'Advertising stopped');
    } else {
      final payload = {
        'user': _user.displayName,
        'instanceId': _instanceId,
        'status': 'available',
      };
      await _blePeripheral.start(
        advertiseData: AdvertiseData(
          manufacturerId: 0xFF,
          manufacturerData: Uint8List.fromList(utf8.encode(jsonEncode(payload))),
        ),
      );
      setState(() => _isAdvertising = true);
      Fluttertoast.showToast(msg: 'Advertising started');
    }
  }

  void _showInvite(String name, String id, {String? senderId}) {
    if (senderId == _instanceId) return;
    if (_deviceStatus.containsKey(id)) return;
    setState(() => _deviceStatus[id] = 'pending');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SessionInviteBubble(
        deviceName: name,
        onAccept: () { Navigator.of(context).pop(); _handleResponse(id, name, true); },
        onDecline: () { Navigator.of(context).pop(); _handleResponse(id, name, false); },
      ),
    );
  }

  void _handleResponse(String id, String name, bool accepted) {
    final now = DateTime.now();
    setState(() {
      _deviceStatus[id] = accepted ? 'connected' : 'declined';
      if (accepted) _startTimes[id] = now;
      else _startTimes.remove(id);
    });
    SessionSyncService.syncSessions([
      Session(
        sessionId: now.millisecondsSinceEpoch.toString(),
        deviceId: id,
        deviceName: name,
        startTime: now,
        status: accepted ? SessionStatus.accepted : SessionStatus.declined,
      )
    ]);
    Fluttertoast.showToast(msg: accepted ? 'Connected to $name' : 'Declined $name');
  }

  void _handleNfcInvite(String peerId, String peerName) {
    _showInvite(peerName, peerId);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'connected': return Colors.blue;
      case 'pending': return Colors.amber;
      case 'declined': return Colors.red;
      default: return Colors.green;
    }
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.inHours}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_user.displayName.isEmpty ? 'Set Display Name' : 'Welcome, ${_user.displayName}'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh)],
      ),
      drawer: AppDrawer(onNavigate: (route) {
        Navigator.of(context).pop();
        if (ModalRoute.of(context)!.settings.name != route) Navigator.of(context).pushReplacementNamed(route);
      }),
      body: _user.displayName.isEmpty
          ? Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed('/profile'),
                child: const Text('Go to Profile'),
              ),
            )
          : Column(
              children: [
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _toggleAdvertising,
                  child: Text(_isAdvertising ? 'Stop' : 'Start'),
                ),
                Expanded(
                  child: StreamBuilder<List<ScanResult>>(
                    stream: _bleService.scanResults,
                    builder: (context, snapshot) {
                      final all = snapshot.data ?? [];
                      final peers = all.where((r) {
                        final adv = r.advertisementData.manufacturerData;
                        if (!adv.containsKey(0xFF)) return false;
                        try {
                          final m = jsonDecode(utf8.decode(adv[0xFF]!)) as Map<String, dynamic>;
                          return m['instanceId'] != _instanceId;
                        } catch (_) {
                          return false;
                        }
                      }).toList();

                      if (peers.isEmpty) return const Center(child: Text('No peers found.'));
                      return ListView.builder(
                        itemCount: peers.length,
                        itemBuilder: (context, i) {
                          final r = peers[i];
                          final id = r.device.remoteId.id;
                          String name = id;
                          String status = _deviceStatus[id] ?? 'unknown';
                          final start = _startTimes[id];
                          try {
                            final m = jsonDecode(utf8.decode(r.advertisementData.manufacturerData[0xFF]!)) as Map<String, dynamic>;
                            name = m['user'] as String? ?? name;
                            status = m['status'] as String? ?? status;
                          } catch (_) {}
                          return ListTile(
                            leading: CircleAvatar(backgroundColor: _statusColor(status), radius: 8),
                            title: Text(name),
                            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Status: $status'),
                              if (status == 'connected' && start != null) Text('Timer: ${_fmt(DateTime.now().difference(start))}'),
                            ]),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              ElevatedButton(
                                onPressed: () => status == 'connected' ? _handleResponse(id, name, false) : _showInvite(name, id),
                                child: Text(status == 'connected' ? 'End' : 'Invite'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  final ip = await _wifiService.getCurrentIP();
                                  if (ip.isEmpty) {
                                    Fluttertoast.showToast(msg: 'Not on Wi-Fi');
                                    return;
                                  }
                                  final uri = Uri.parse('http://$ip:8080/invite');
                                  try {
                                    await http.post(
                                      uri,
                                      headers: {'Content-Type': 'application/json'},
                                      body: jsonEncode({'from': _user.displayName, 'instanceId': _instanceId, 'sessionId': DateTime.now().millisecondsSinceEpoch.toString()}),
                                    );
                                    Fluttertoast.showToast(msg: 'Wi-Fi invite sent');
                                  } catch (e) {
                                    Fluttertoast.showToast(msg: 'Error: $e');
                                  }
                                },
                                child: const Text('Wi-Fi'),
                              ),
                            ]),
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
