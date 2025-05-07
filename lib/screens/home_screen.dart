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

import '../widgets/app_drawer.dart';
import '../widgets/session_invite_bubble.dart';
import '../models/user_model.dart';
import '../models/session.dart';
import '../services/ble_service.dart';
import '../services/session_sync_service.dart';
import '../services/network_discovery_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BleService _bleService = BleService();
  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();
  final NetworkDiscoveryService _netDisc = NetworkDiscoveryService();
  final String _instanceId = const Uuid().v4();

  late UserModel _user;
  StreamSubscription<List<ScanResult>>? _scanSub;
  RawDatagramSocket? _inviteSocket;

  bool _isAdvertising = false;
  bool _initialized = false;

  final Map<String, _PeerData> _peers = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (Platform.isAndroid) {
      final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt ?? 0;
      final perms = <Permission>[];
      if (sdk < 31) {
        perms.add(Permission.locationWhenInUse);
      } else {
        perms.addAll([
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
        ]);
      }
      final statuses = await perms.request();
      if (statuses.values.any((s) => !s.isGranted)) {
        Fluttertoast.showToast(msg: 'Permissions not granted');
        return;
      }
    }
    _startBleScan();
    await _startInviteSocket();
  }

  Future<void> _startBleScan() async {
    try {
      await _bleService.startScan();
      _scanSub = _bleService.scanResults.listen(_handleBleResults);
    } catch (e) {
      debugPrint('[BLE] Scan error: $e');
    }
  }

  Future<void> _startInviteSocket() async {
    try {
      _inviteSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, NetworkDiscoveryService.port);
      _inviteSocket!.broadcastEnabled = true;
      _inviteSocket!.listen(_handleUdpEvent);
    } catch (e) {
      debugPrint('[UDP] Bind error: $e');
    }
  }

  void _handleBleResults(List<ScanResult> results) {
    for (final r in results) {
      final adv = r.advertisementData.manufacturerData;
      if (!adv.containsKey(0xFF)) continue;
      try {
        final data = utf8.decode(adv[0xFF]!);
        final map = jsonDecode(data) as Map<String, dynamic>;
        if (map['proto'] != 'ath-prox-v1') continue;
        final peerId = map['instanceId'] as String?;
        if (peerId == null || peerId == _instanceId) continue;
        final name = map['user'] as String? ?? 'Unknown';
        _addOrUpdatePeer(peerId, name, source: 'ble');
        if (map['type'] == 'invite' && map['targetId'] == _instanceId) {
          _showIncomingInvite(name, peerId);
        }
      } catch (e) {
        debugPrint('[BLE] Parse error: $e');
      }
    }
  }

  void _handleUdpEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final dg = _inviteSocket?.receive();
    if (dg == null) return;
    try {
      final map = jsonDecode(utf8.decode(dg.data)) as Map<String, dynamic>;
      if (map['proto'] != 'ath-prox-v1') return;
      final peerId = map['instanceId'] as String?;
      if (peerId == null || peerId == _instanceId) return;
      final name = map['from'] as String? ?? 'Unknown';
      _addOrUpdatePeer(peerId, name, source: 'wifi', ip: dg.address.address);
      if (map['type'] == 'invite' && map['targetId'] == _instanceId) {
        _showIncomingInvite(name, peerId);
      }
    } catch (e) {
      debugPrint('[UDP PARSE ERROR] $e');
    }
  }

  void _addOrUpdatePeer(String id, String name, {required String source, String? ip}) {
    if (id == _instanceId) return;
    final existing = _peers[id];
    if (existing == null) {
      _peers[id] = _PeerData(id: id, name: name, ip: ip);
    } else {
      existing.name = name;
      if (ip != null) existing.ip = ip;
    }
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _user = Provider.of<UserModel>(context);
      if (_user.displayName.trim().isNotEmpty) {
        _netDisc.start(_user.displayName);
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _bleService.stopScan();
    _blePeripheral.stop();
    _netDisc.stop();
    _inviteSocket?.close();
    super.dispose();
  }

  Future<void> _toggleAdvertising() async {
    if (_isAdvertising) {
      await _blePeripheral.stop();
      setState(() => _isAdvertising = false);
    } else {
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
  }

  void _refresh() {
    _scanSub?.cancel();
    _bleService.stopScan();
    _peers.clear();
    setState(() {});
    Future.delayed(const Duration(milliseconds: 500), _startBleScan);
  }

  Future<void> _invitePeer(_PeerData peer) async {
    if (peer.status != 'available') return;
    setState(() => peer.status = 'pending');
    final msg = {
      'proto': 'ath-prox-v1',
      'type': 'invite',
      'from': _user.displayName,
      'instanceId': _instanceId,
      'targetId': peer.id,
    };
    if (peer.ip != null) {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.send(utf8.encode(jsonEncode(msg)), InternetAddress(peer.ip!), NetworkDiscoveryService.port);
      socket.close();
    }
    Fluttertoast.showToast(msg: 'Invite sent to ${peer.name}');
  }

  void _showIncomingInvite(String name, String id) {
    final peer = _peers[id];
    if (peer == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
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
    });
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
  Widget build(BuildContext context) {
    final nameSet = _user.displayName.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(nameSet ? 'Welcome, ${_user.displayName}' : 'Set Display Name'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh)],
      ),
      drawer: AppDrawer(onNavigate: (route) {
        Navigator.of(context).pop();
        if (ModalRoute.of(context)!.settings.name != route) {
          Navigator.of(context).pushReplacementNamed(route);
        }
      }),
      body: nameSet
          ? Column(
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
                                    ? Colors.green
                                    : peer.status == 'pending'
                                        ? Colors.orange
                                        : Colors.grey,
                              ),
                              title: Text(peer.name),
                              subtitle: Text('Status: ${peer.status}'),
                              trailing: ElevatedButton(
                                onPressed: () => _invitePeer(peer),
                                child: Text(peer.status == 'connected' ? 'End' : 'Invite'),
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
                child: const Text('Set Your Name'),
              ),
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
  _PeerData({required this.id, required this.name, this.status = 'available', this.startTime, this.ip});
}
