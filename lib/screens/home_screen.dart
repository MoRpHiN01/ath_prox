import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/user_model.dart';
import '../models/session.dart';
import '../services/ble_service.dart';
import '../services/network_discovery_service.dart';
import '../services/session_sync_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/session_invite_bubble.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _PeerData {
  final String id;
  String name;
  String status;
  DateTime? startTime;
  String? ip;

  _PeerData({required this.id, required this.name, this.status = 'available', this.startTime, this.ip});
}

class _HomeScreenState extends State<HomeScreen> {
  final BleService _bleService = BleService();
  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();
  final NetworkDiscoveryService _netDisc = NetworkDiscoveryService();
  final Map<String, _PeerData> _peers = {};
  final String _instanceId = const Uuid().v4();

  bool _isAdvertising = false;
  bool _initialized = false;
  late UserModel _user;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (Platform.isAndroid) {
      await [
        Permission.locationWhenInUse,
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect
      ].request();
    }

    FlutterBluePlus.adapterState.listen((state) {
      if (state != BluetoothAdapterState.on) {
        Fluttertoast.showToast(msg: 'Bluetooth must be ON');
      }
    });

    final stream = _bleService.startScan();
    stream.listen(_handleResult, onError: (e) {
      Fluttertoast.showToast(msg: '[BLE_SCAN ERROR] $e');
    });
  }

  void _handleResult(ScanResult r) {
    final peerId = _bleService.extractInstanceId(r);
    if (peerId == null || peerId == _instanceId) return;
    final name = _bleService.extractDisplayName(r);
    final status = _bleService.extractStatus(r);

    if (!_peers.containsKey(peerId)) {
      _peers[peerId] = _PeerData(id: peerId, name: name, status: status);
    } else {
      _peers[peerId]!.status = status;
      _peers[peerId]!.name = name;
    }
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _user = Provider.of<UserModel>(context);
      _netDisc.start(_user.displayName, onFound: _handleNetPeer);
      _initialized = true;
    }
  }

  void _handleNetPeer(String id, String name, String ip) {
    if (id == _instanceId) return;
    if (!_peers.containsKey(id)) {
      _peers[id] = _PeerData(id: id, name: name, ip: ip);
    } else {
      _peers[id]!.ip = ip;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _blePeripheral.stop();
    _netDisc.stop();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future<void> _toggleAdvertising() async {
    if (_isAdvertising) {
      await _blePeripheral.stop();
      setState(() => _isAdvertising = false);
      return;
    }

    final payload = {
      'proto': 'ath-prox-v1',
      'type': 'status',
      'user': _user.displayName,
      'instanceId': _instanceId,
    };

    await _blePeripheral.start(
      advertiseData: AdvertiseData(
        manufacturerId: 0xFF,
        manufacturerData: Uint8List.fromList(utf8.encode(jsonEncode(payload))),
      ),
    );
    setState(() => _isAdvertising = true);
  }

  void _invitePeer(_PeerData peer) async {
    if (peer.id == _instanceId) return;
    if (peer.status != 'available') return;

    setState(() => peer.status = 'pending');

    final sent = await _netDisc.sendInvite(
      fromName: _user.displayName,
      fromId: _instanceId,
      targetId: peer.id,
      targetIp: peer.ip,
    );

    if (!sent) {
      final payload = {
        'proto': 'ath-prox-v1',
        'type': 'invite',
        'from': _user.displayName,
        'instanceId': _instanceId,
        'targetId': peer.id,
      };

      await _blePeripheral.start(
        advertiseData: AdvertiseData(
          manufacturerId: 0xFF,
          manufacturerData: Uint8List.fromList(utf8.encode(jsonEncode(payload))),
        ),
      );
    }
  }

  void _handleInvite(String name, String id) {
    final peer = _peers[id];
    if (peer == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SessionInviteBubble(
        deviceName: name,
        onAccept: () {
          Navigator.of(context).pop();
          _respond(peer, true);
        },
        onDecline: () {
          Navigator.of(context).pop();
          _respond(peer, false);
        },
      ),
    );
  }

  void _respond(_PeerData peer, bool accept) {
    final now = DateTime.now();
    setState(() {
      peer.status = accept ? 'connected' : 'declined';
      peer.startTime = accept ? now : null;
    });
    SessionSyncService.syncSessions([
      Session(
        sessionId: now.millisecondsSinceEpoch.toString(),
        deviceId: peer.id,
        deviceName: peer.name,
        startTime: now,
        status: accept ? SessionStatus.accepted : SessionStatus.declined,
      )
    ]);
  }

  void _refresh() {
    _peers.clear();
    setState(() {});
    _init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_user.displayName.isNotEmpty ? 'Welcome, ${_user.displayName}' : 'Set Display Name'),
        actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))],
      ),
      drawer: AppDrawer(onNavigate: (r) => Navigator.pushReplacementNamed(context, r)),
      body: _user.displayName.isEmpty
          ? Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/profile'),
                child: const Text('Set Your Name'),
              ),
            )
          : Column(
              children: [
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _toggleAdvertising,
                  child: Text(_isAdvertising ? 'Stop Advertising' : 'Start Advertising'),
                ),
                Expanded(
                  child: _peers.isEmpty
                      ? const Center(child: Text('No peers found'))
                      : ListView(
                          children: _peers.values.map((peer) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: peer.status == 'connected'
                                    ? Colors.green
                                    : peer.status == 'pending'
                                        ? Colors.amber
                                        : Colors.grey,
                              ),
                              title: Text(peer.name),
                              subtitle: peer.startTime != null
                                  ? Text('Timer: ${_formatDuration(DateTime.now().difference(peer.startTime!))}')
                                  : Text('Status: ${peer.status}'),
                              trailing: ElevatedButton(
                                onPressed: () => _invitePeer(peer),
                                child: const Text('Invite'),
                              ),
                            );
                          }).toList(),
                        ),
                )
              ],
            ),
    );
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }
}
