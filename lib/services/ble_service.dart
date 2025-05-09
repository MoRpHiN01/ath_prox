
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/peer.dart';

class BleService {
  final FlutterBluePlus _bluetooth = FlutterBluePlus();
  final List<Peer> discoveredPeers = [];

  Future<void> startScan(Function(Peer) onPeerFound) async {
    await _bluetooth.startScan(timeout: Duration(seconds: 5));
    _bluetooth.scanResults.listen((results) {
      for (var result in results) {
        // Simulate parsing BLE advertisement to Peer
        final peer = Peer(instanceId: result.device.id.toString(), displayName: result.device.name, status: 'available');
        discoveredPeers.add(peer);
        onPeerFound(peer);
      }
    });
  }

  Future<void> stopScan() async {
    await _bluetooth.stopScan();
  }
}
