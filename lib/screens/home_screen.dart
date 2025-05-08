
import 'package:flutter/material.dart';
import 'package:proximity/services/ble_service.dart';
import 'package:proximity/models/peer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late BleService _bleService;
  List<Peer> _peers = [];

  @override
  void initState() {
    super.initState();
    _bleService = BleService(onPeerFound: _onPeerFound);
    _bleService.startScan();
  }

  void _onPeerFound(Peer peer) {
    setState(() {
      _peers.removeWhere((p) => p.instanceId == peer.instanceId);
      _peers.add(peer);
    });
  }

  @override
  void dispose() {
    _bleService.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Devices'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _bleService.stopScan();
              _bleService.startScan();
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _peers.length,
        itemBuilder: (context, index) {
          final peer = _peers[index];
          return ListTile(
            title: Text(peer.displayName),
            subtitle: Text(peer.status),
          );
        },
      ),
    );
  }
}
