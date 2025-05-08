// lib/screens/home_screen.dart

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

class _HomeScreenState extends State<HomeScreen> {
  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();
  final BleService _bleService = BleService();
  final NetworkDiscoveryService _netDisc = NetworkDiscoveryService();
  final String _instanceId = const Uuid().v4();
  late UserModel _user;

  final Map<String, _PeerData> _peers = {};
  bool _isAdvertising = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkPermissions();
    _user = Provider.of<UserModel>(context, listen: false);
    _netDisc.start(_user.displayName, _handleNetPeer, _instanceId);
    _bleService.startScan().listen(_handleBleResult);
    _broadcastStatus();
  }

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      final sdk = (await _bleService.getAndroidSdkInt());
      if (sdk < 31) {
        await Permission.locationWhenInUse.request();
      } else {
        await [
          Permission.bluetoothAdvertise,
          Permission.bluetoothConnect,
          Permission.bluetoothScan,
        ].request();
      }
    }
  }

  void _handleBleResult(ScanResult result) {
    final id = _bleService.extractInstanceId(result);
    if (id == null || id == _instanceId) return;

    final type = _bleService.extractType(result);
    if (type == 'invite') {
      final name = _bleService.extractDisplayName(result);
      final target = _bleService.extractTargetId(result);
      if (target == _instanceId) _showInvite(name, id);
    } else if (type == 'status') {
      final name = _bleService.extractDisplayName(result);
      _peers[id] = _PeerData(id: id, name: name);
      setState(() {});
    }
  }

  void _handleNetPeer(String id, String name, String? ip) {
    if (id == _instanceId) return;
    _peers[id] = _PeerData(id: id, name: name, ip: ip);
    setState(() {});
  }

  void _broadcastStatus() {
    _netDisc.broadcastStatus(_user.displayName, _instanceId);
  }

  Future<void> _toggleAdvertising() async {
    if (_isAdvertising) {
      await _blePeripheral.stop();
      setState(() => _isAdvertising = false);
      return;
    }

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

  Future<void> _invitePeer(_PeerData peer) async {
    if (peer.status != 'available') return;
    setState(() => peer.status = 'pending');

    final success = await _netDisc.sendInvite(
      toId: peer.id,
      fromName: _user.displayName,
      fromId: _instanceId,
      targetIp: peer.ip,
    );

    if (!success) {
      final fallbackPayload = jsonEncode({
        'proto': 'ath-prox-v1',
        'type': 'invite',
        'from': _user.displayName,
        'instanceId': _instanceId,
        'targetId': peer.id,
      });

      await _blePeripheral.start(
        advertiseData: AdvertiseData(
          manufacturerId: 0xFF,
          manufacturerData: Uint8List.fromList(utf8.encode(fallbackPayload)),
        ),
      );
    }
  }

  void _showInvite(String name, String id) {
    final peer = _peers[id];
    if (peer == null) return;

    showDialog(
      context: context,
      builder: (_) => SessionInviteBubble(
        deviceName: name,
        onAccept: () {
          Navigator.of(context).pop();
          _handleResponse(peer, true);
        },
        onDecline: () {
          Navigator.of(context).pop();
          _handleResponse(peer, false);
        },
      ),
    );
  }

  void _handleResponse(_PeerData peer, bool accepted) {
    final now = DateTime.now();
    setState(() => peer.status = accepted ? 'connected' : 'declined');
    peer.startTime = accepted ? now : null;
    SessionSyncService.syncSessions([
      Session(
        sessionId: now.millisecondsSinceEpoch.toString(),
        deviceId: peer.id,
        deviceName: peer.name,
        startTime: now,
        status: accepted ? SessionStatus.accepted : SessionStatus.declined,
      )
    ]);
  }

  @override
  void dispose() {
    _blePeripheral.stop();
    _netDisc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_user.displayName.isNotEmpty ? 'Welcome, ${_user.displayName}' : 'Set Your Name'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _broadcastStatus)],
      ),
      drawer: AppDrawer(onNavigate: (route) {
        Navigator.of(context).pop();
        if (ModalRoute.of(context)?.settings.name != route) {
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
                ? const Center(child: Text('No peers found'))
                : ListView(
                    children: _peers.values.map((peer) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: peer.status == 'connected'
                              ? Colors.green
                              : peer.status == 'pending'
                                  ? Colors.orange
                                  : Colors.grey,
                        ),
                        title: Text(peer.name),
                        subtitle: peer.startTime != null
                            ? Text('Started: ${peer.startTime}')
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
