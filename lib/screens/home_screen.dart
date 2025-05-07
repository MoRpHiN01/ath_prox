// lib/screens/home_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  final BleService _bleService = BleService();
  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();
  final NetworkDiscoveryService _netDisc = NetworkDiscoveryService();
  final String _instanceId = const Uuid().v4();

  late UserModel _user;
  bool _isAdvertising = false;
  final Map<String, _PeerData> _peers = {};

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      final sdkInt = (await Permission.location.status).isGranted;
      await [
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise
      ].request();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _user = Provider.of<UserModel>(context);
    _netDisc.start(_user.displayName, _handleNetPeer);

    _bleService.startScan().listen(_handleResult, onError: (e) {
      Fluttertoast.showToast(msg: '[BLE] Scan failed: $e');
    });
  }

  void _handleResult(ScanResult r) {
    final peerId = _bleService.extractInstanceId(r);
    if (peerId == null || peerId == _instanceId) return;

    final name = _bleService.extractDisplayName(r);
    final type = _bleService.extractType(r);

    if (type == 'invite') {
      _showInvite(name, peerId);
    } else {
      _addOrUpdatePeer(peerId, name);
    }
  }

  void _handleNetPeer(String id, String user, String? ip) {
    if (id == _instanceId) return;
    _addOrUpdatePeer(id, user, ip: ip);
  }

  void _addOrUpdatePeer(String id, String name, {String? ip}) {
    final p = _peers[id];
    if (p == null) {
      _peers[id] = _PeerData(id: id, name: name, ip: ip);
    } else {
      p.name = name;
      if (ip != null) p.ip = ip;
    }
    setState(() {});
  }

  void _showInvite(String name, String id) {
    final peer = _peers[id];
    if (peer == null) return;
    showDialog(
      context: context,
      builder: (_) => SessionInviteBubble(
        deviceName: name,
        onAccept: () => _handleResponse(peer, true),
        onDecline: () => _handleResponse(peer, false),
      ),
    );
  }

  void _handleResponse(_PeerData peer, bool accepted) {
    setState(() => peer.status = accepted ? 'connected' : 'declined');
    SessionSyncService.syncSessions([
      Session(
        sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
        deviceId: peer.id,
        deviceName: peer.name,
        startTime: DateTime.now(),
        status: accepted ? SessionStatus.accepted : SessionStatus.declined,
      )
    ]);
  }

  Future<void> _advertiseStatus() async {
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

  Future<void> _sendInvite(_PeerData peer) async {
    final success = await _netDisc.sendInvite(
      from: _user.displayName,
      fromId: _instanceId,
      targetId: peer.id,
      targetIp: peer.ip,
    );
    setState(() => peer.status = success ? 'pending' : 'declined');
  }

  @override
  Widget build(BuildContext context) {
    final nameSet = _user.displayName.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(nameSet ? 'Welcome, ${_user.displayName}' : 'Set Display Name'),
        actions: [IconButton(onPressed: _advertiseStatus, icon: const Icon(Icons.wifi))],
      ),
      drawer: AppDrawer(onNavigate: (r) => Navigator.of(context).pushReplacementNamed(r)),
      body: nameSet
          ? Column(
              children: [
                ElevatedButton(
                  onPressed: _advertiseStatus,
                  child: Text(_isAdvertising ? 'Stop Advertising' : 'Start Advertising'),
                ),
                Expanded(
                  child: _peers.isEmpty
                      ? const Center(child: Text('No peers found.'))
                      : ListView(
                          children: _peers.values.map((p) {
                            return ListTile(
                              leading: CircleAvatar(radius: 8),
                              title: Text(p.name),
                              subtitle: Text('Status: ${p.status}'),
                              trailing: ElevatedButton(
                                onPressed: () => _sendInvite(p),
                                child: const Text('Invite'),
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            )
          : Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed('/profile'),
                child: const Text('Set Display Name'),
              ),
            ),
    );
  }
}

class _PeerData {
  final String id;
  String name;
  String status;
  String? ip;
  _PeerData({required this.id, required this.name, this.status = 'available', this.ip});
}
