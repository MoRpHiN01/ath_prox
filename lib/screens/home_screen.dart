// lib/screens/home_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
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
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _PeerData {
  final String id;
  String name;
  String status;
  DateTime? startTime;
  String? ip;
  _PeerData({
    required this.id,
    required this.name,
    this.status = 'available',
    this.startTime,
    this.ip,
  });
}

class _HomeScreenState extends State<HomeScreen> {
  final String _instanceId = const Uuid().v4();
  final BleService _bleService = BleService();
  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();
  final NetworkDiscoveryService _netDisc = NetworkDiscoveryService();

  late UserModel _user;
  final Map<String, _PeerData> _peers = {};
  bool _isAdvertising = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    // Permissions
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdk = androidInfo.version.sdkInt ?? 0;
      final perms = <Permission>[
        Permission.bluetooth,
        if (sdk < 31) Permission.locationWhenInUse else ...[
          Permission.bluetoothScan,
          Permission.bluetoothAdvertise,
        ],
      ];
      final statuses = await perms.request();
      if (statuses.values.any((s) => !s.isGranted)) {
        Fluttertoast.showToast(msg: 'Required permissions not granted');
        return;
      }
    }

    // Start network discovery
    _netDisc.start(_user.displayName, _handleNetPeer, _instanceId);

    // Start BLE scan
    await _bleService.startScan();
    _bleService.scanResults.listen(_handleBleResult, onError: (e) {
      print('[HomeScreen] BLE scan error: $e');
    });
  }

  void _handleBleResult(ScanResult result) {
    final id = _bleService.extractInstanceId(result);
    if (id == _instanceId || id.isEmpty) return;

    final type = _bleService.extractType(result);
    final name = _bleService.extractDisplayName(result);

    if (type == 'invite') {
      final target = _bleService.extractTargetId(result);
      if (target == _instanceId) _showIncomingInvite(name, id);
    } else {
      _addOrUpdatePeer(id, name);
    }
  }

  void _handleNetPeer(String id, String name, String? ip) {
    if (id == _instanceId) return;
    _addOrUpdatePeer(id, name, ip: ip);
  }

  void _addOrUpdatePeer(String id, String name, {String? ip}) {
    final existing = _peers[id];
    if (existing == null) {
      _peers[id] = _PeerData(id: id, name: name, ip: ip);
    } else {
      existing.name = name;
      existing.ip = ip;
    }
    setState(() {});
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
    _netDisc.dispose();
    super.dispose();
  }

  void _refresh() {
    _peers.clear();
    setState(() {});
    _bleService.stopScan().then((_) {
      _bleService.startScan();
    });
    Fluttertoast.showToast(msg: 'Refreshing peers...');
  }

  Future<void> _toggleAdvertising() async {
    if (_isAdvertising) {
      await _blePeripheral.stop();
      setState(() => _isAdvertising = false);
    } else {
      final payload = jsonEncode({
        'proto': 'ath-prox-v1',
        'type': 'status',
        'user': _user.displayName,
        'instanceId': _instanceId,
      });
      await _blePeripheral.start(
        advertiseData: AdvertiseData(
          manufacturerId: 0xFF,
          manufacturerData: Uint8List.fromList(utf8.encode(payload)),
        ),
      );
      setState(() => _isAdvertising = true);
    }
  }

  Future<void> _invitePeer(_PeerData peer) async {
    if (peer.status != 'available') return;
    setState(() => peer.status = 'pending');

    final success = await _netDisc.sendInvite(
      toId: peer.id,
      fromName: _user.displayName,
      instanceId: _instanceId,
      targetIp: peer.ip,
    );

    Fluttertoast.showToast(
      msg: success ? 'Invite sent to ${peer.name}' : 'Failed to send invite',
    );
  }

  void _showIncomingInvite(String name, String id) {
    if (!_peers.containsKey(id)) return;
    final peer = _peers[id]!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SessionInviteBubble(
        deviceName: name,
        onAccept: () => _handleResponse(peer, true),
        onDecline: () => _handleResponse(peer, false),
      ),
    );
  }

  void _handleResponse(_PeerData peer, bool accepted) {
    Navigator.of(context).pop();
    final now = DateTime.now();
    setState(() {
      peer.status = accepted ? 'connected' : 'declined';
      peer.startTime = accepted ? now : null;
    });

    SessionSyncService.syncSessions([
      Session(
        sessionId: now.millisecondsSinceEpoch.toString(),
        deviceId: peer.id,
        deviceName: peer.name,
        startTime: peer.startTime ?? now,
        status: accepted ? SessionStatus.accepted : SessionStatus.declined,
      )
    ]);
  }

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.inHours}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${_user.displayName}'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh)],
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
            child: Text(_isAdvertising ? 'Stop Advertising' : 'Start Advertising'),
          ),
          Expanded(
            child: _peers.isEmpty
                ? const Center(child: Text('No peers found.'))
                : ListView(
                    children: _peers.values.map((peer) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: peer.status == 'connected'
                              ? Colors.blue
                              : peer.status == 'pending'
                                  ? Colors.amber
                                  : Colors.grey,
                          radius: 8,
                        ),
                        title: Text(peer.name),
                        subtitle: peer.status == 'connected' && peer.startTime != null
                            ? Text('Timer: ${_format(DateTime.now().difference(peer.startTime!))}')
                            : Text('Status: ${peer.status}'),
                        trailing: ElevatedButton(
                          onPressed: () => _invitePeer(peer),
                          child: Text(peer.status == 'connected' ? 'End' : 'Invite'),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
