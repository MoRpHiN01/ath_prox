// Due to the size and complexity of the complete home_screen.dart rebuild,
// and to ensure clarity, performance, and full integration, this response will include:
// - All peer filtering and user info fixes
// - Safety checks on displayName / peer names
// - Toast and debug improvements
// - Invite logic checks
//
// BEGIN FULL home_screen.dart REBUILD

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
        Fluttertoast.showToast(msg: 'Required permissions not granted');
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
      Fluttertoast.showToast(msg: 'BLE scan error: $e');
    }
  }

  Future<void> _startInviteSocket() async {
    try {
      _inviteSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, NetworkDiscoveryService.port);
      _inviteSocket!.broadcastEnabled = true;
      _inviteSocket!.listen(_handleUdpEvent);
    } catch (e) {
      Fluttertoast.showToast(msg: 'UDP socket error: $e');
    }
  }

  void _handleBleResults(List<ScanResult> results) {
    for (final r in results) {
      final adv = r.advertisementData.manufacturerData;
      if (!adv.containsKey(0xFF)) continue;
      try {
        final map = jsonDecode(utf8.decode(adv[0xFF]!)) as Map<String, dynamic>;
        if (map['proto'] != 'ath-prox-v1') continue;
        final peerId = map['instanceId'] as String?;
        if (peerId == null || peerId == _instanceId) continue; // filter self

        if (map['type'] == 'invite' && map['targetId'] == _instanceId) {
          final from = map['from'] as String? ?? 'Unknown';
          _addOrUpdatePeer(peerId, from, source: 'ble');
          _showIncomingInvite(from, peerId);
        } else if (map['type'] == 'status') {
          final user = map['user'] as String? ?? 'Unknown';
          _addOrUpdatePeer(peerId, user, source: 'ble');
        }
      } catch (e) {
        debugPrint('[BLE_PARSE] Error: $e');
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

      final type = map['type'] as String?;
      if (type == 'invite' && map['targetId'] == _instanceId) {
        final from = map['from'] as String? ?? 'Unknown';
        _addOrUpdatePeer(peerId, from, source: 'wifi', ip: dg.address.address);
        _showIncomingInvite(from, peerId);
      } else if (type == 'status') {
        final user = map['user'] as String? ?? 'Unknown';
        _addOrUpdatePeer(peerId, user, source: 'wifi', ip: dg.address.address);
      }
    } catch (e) {
      debugPrint('[UDP_PARSE] Error: $e');
    }
  }

  void _addOrUpdatePeer(String id, String name, {required String source, String? ip}) {
    if (id == _instanceId) return; // never show self
    final existing = _peers[id];
    if (existing == null) {
      _peers[id] = _PeerData(id: id, name: name, ip: ip);
    } else {
      existing.name = name;
      if (ip != null) existing.ip = ip;
    }
    setState(() {});
  }

  void _showIncomingInvite(String name, String id) {
    final peer = _peers[id];
    if (peer == null) return;
    debugPrint('[INVITE_RECEIVED] from: $name ($id)');
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
    Fluttertoast.showToast(
      msg: accepted
          ? 'Connected to ${peer.name.isNotEmpty ? peer.name : "Unknown"}'
          : 'Declined ${peer.name.isNotEmpty ? peer.name : "Unknown"}',
    );
  }

  Future<void> _toggleAdvertising() async {
    if (_isAdvertising) {
      await _blePeripheral.stop();
      setState(() => _isAdvertising = false);
      Fluttertoast.showToast(msg: 'Stopped advertising');
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
      Fluttertoast.showToast(msg: 'Started advertising');
    }
  }

  void _refresh() {
    _scanSub?.cancel();
    _bleService.stopScan();
    _peers.clear();
    setState(() {});
    Future.delayed(const Duration(milliseconds: 300), _startBleScan);
    Fluttertoast.showToast(msg: 'Peer list refreshed');
  }

  void _invitePeer(_PeerData peer) {
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
      RawDatagramSocket.bind(InternetAddress.anyIPv4, 0).then((socket) {
        socket.send(utf8.encode(jsonEncode(msg)), InternetAddress(peer.ip!), NetworkDiscoveryService.port);
        socket.close();
        debugPrint('[INVITE] Sent over WiFi to ${peer.name}');
      });
    } else {
      debugPrint('[INVITE] BLE fallback to ${peer.name}');
      _toggleAdvertising();
    }
    Fluttertoast.showToast(msg: 'Invite sent to ${peer.name.isNotEmpty ? peer.name : "Unknown"}');
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

  String _format(DateTime start) {
    final d = DateTime.now().difference(start);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.inHours}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
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
                                        ? Colors.amber
                                        : Colors.grey,
                                radius: 8,
                              ),
                              title: Text(peer.name),
                              subtitle: peer.status == 'connected' && peer.startTime != null
                                  ? Text('Timer: ${_format(peer.startTime!)}')
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
