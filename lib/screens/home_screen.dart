import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/peer.dart';
import '../models/user_model.dart';
import '../services/ble_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late BleService _bleService;
  final List<Peer> _peers = [];

  @override
  void initState() {
    super.initState();
    _bleService = BleService(
      onPeerFound: (peer) {
        final existingIndex = _peers.indexWhere((p) => p.instanceId == peer.instanceId);
        if (existingIndex == -1) {
          setState(() => _peers.add(peer));
        } else {
          setState(() => _peers[existingIndex] = peer);
        }
      },
      onError: (e) => debugPrint('BLE error: $e'),
    );
    _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    await _bleService.startScan();
  }

  @override
  void dispose() {
    _bleService.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _peers.clear());
              _startDiscovery();
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _peers.length,
        itemBuilder: (context, index) {
          final peer = _peers[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.device_hub)),
            title: Text(peer.displayName),
            subtitle: Text(peer.status),
            trailing: ElevatedButton(
              onPressed: peer.status == 'available'
                  ? () {
                      setState(() {
                        _peers[index] = peer.copyWith(status: 'pending');
                      });
                      _bleService.sendInvite(peer.instanceId);
                    }
                  : null,
              child: Text(peer.status == 'pending' ? 'Invited' : 'Invite'),
            ),
          );
        },
      ),
    );
  }
}
