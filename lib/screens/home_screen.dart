import 'package:flutter/material.dart';
import 'package:proximity/models/peer.dart';
import 'package:proximity/services/ble_service.dart';
import 'package:proximity/services/user_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BleService _bleService = BleService();
  final List<Peer> _peers = [];

  bool _isAdvertising = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _bleService.init(
      onPeerDiscovered: (peer) {
        setState(() {
          _peers.removeWhere((p) => p.instanceId == peer.instanceId);
          _peers.add(peer);
        });
      },
    );
    await _bleService.startAdvertising();
    await _bleService.startScan();
    setState(() {
      _isAdvertising = true;
    });
  }

  void _toggleAdvertising() async {
    if (_isAdvertising) {
      await _bleService.stopAdvertising();
    } else {
      await _bleService.startAdvertising();
    }
    setState(() {
      _isAdvertising = !_isAdvertising;
    });
  }

  @override
  void dispose() {
    _bleService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ATH PROXIMITY - GET CONNECTED'),
        actions: [
          IconButton(
            icon: Icon(_isAdvertising ? Icons.bluetooth_disabled : Icons.bluetooth),
            onPressed: _toggleAdvertising,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _bleService.refreshScan();
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _peers.length,
        itemBuilder: (context, index) {
          final peer = _peers[index];
          return ListTile(
            leading: const Icon(Icons.device_hub),
            title: Text(peer.displayName),
            subtitle: Text('Status: ${peer.status}'),
            trailing: ElevatedButton(
              child: Text(peer.status == 'in_session' ? 'End' : 'Invite'),
              onPressed: () {
                if (peer.status == 'in_session') {
                  _bleService.endSession(peer.instanceId);
                } else {
                  _bleService.sendInvite(peer.instanceId);
                }
              },
            ),
          );
        },
      ),
    );
  }
}