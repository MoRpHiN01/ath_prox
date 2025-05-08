// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/peer.dart';
import '../services/ble_service.dart';
import '../services/wifi_service.dart';
import '../services/nfc_service.dart';
import '../models/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Peer> _peers = [];
  late BleService _bleService;
  late WifiService _wifiService;
  late NfcService _nfcService;
  bool _advertising = false;

  @override
  void initState() {
    super.initState();
    _bleService = BleService(onPeerFound: _addOrUpdatePeer);
    _wifiService = WifiService(onPeerDiscovered: _addOrUpdatePeer);
    _nfcService = NfcService();
    _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    await _bleService.startScan();
    await _wifiService.startBroadcast(Peer(
      instanceId: 'your_instance_id',
      displayName: 'Your Device Name',
      status: 'available',
    ));
    await _nfcService.startSession((id) {
      // Handle NFC discovery
      // For example, create a Peer object and add/update it
    });
  }

  void _addOrUpdatePeer(Peer peer) {
    setState(() {
      final index = _peers.indexWhere((p) => p.instanceId == peer.instanceId);
      if (index == -1) {
        _peers.add(peer);
      } else {
        _peers[index] = peer;
      }
    });
  }

  void _toggleAdvertising() async {
    final user = Provider.of<UserModel>(context, listen: false);
    if (_advertising) {
      await _bleService.stopAdvertising();
    } else {
      await _bleService.startAdvertising(user.displayName, 'available');
    }
    setState(() => _advertising = !_advertising);
  }

  Widget _buildPeerTile(Peer peer) {
    final color = _statusColor(peer.status);
    final label = peer.status == 'in_session' ? 'End Session' : 'Invite';

    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color),
        title: Text(peer.displayName),
        subtitle: Text('Status: ${peer.status}'),
        trailing: ElevatedButton(
          onPressed: () => _onPeerAction(peer),
          child: Text(label),
        ),
      ),
    );
  }

  void _onPeerAction(Peer peer) async {
    if (peer.status == 'in_session') {
      // Implement end session logic
    } else {
      // Implement invite logic
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'in_session':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ATH PROXIMITY - GET CONNECTED'),
            Text(user.displayName, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startDiscovery,
          ),
          IconButton(
            icon: Icon(_advertising ? Icons.stop : Icons.campaign),
            onPressed: _toggleAdvertising,
          )
        ],
      ),
      body: ListView(
        children: _peers.map(_buildPeerTile).toList(),
      ),
    );
  }
}
