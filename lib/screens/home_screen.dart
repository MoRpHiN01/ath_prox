
import 'package:flutter/material.dart';
import '../services/ble_service.dart';
import '../models/peer.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BleService _bleService = BleService();
  List<Peer> _peers = [];

  @override
  void initState() {
    super.initState();
    _bleService.startScan((peer) {
      setState(() {
        _peers.add(peer);
      });
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
      appBar: AppBar(title: Text("ATH PROXIMITY - GET CONNECTED")),
      body: ListView.builder(
        itemCount: _peers.length,
        itemBuilder: (context, index) {
          final peer = _peers[index];
          return ListTile(
            title: Text(peer.displayName),
            subtitle: Text(peer.status),
            trailing: Icon(Icons.bluetooth),
          );
        },
      ),
    );
  }
}
