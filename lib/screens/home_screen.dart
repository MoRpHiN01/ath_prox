// lib/screens/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:logger/logger.dart';

import '../models/peer.dart';
import '../services/ble_service.dart';
import '../services/ble_advertiser.dart';
import '../services/network_discovery_service.dart';
import '../services/user_model.dart';
import '../widgets/session_invite_bubble.dart';

/// Main screen displaying nearby peers and managing scan/advertise.
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Peer> _peers = [];
  late final BleService _bleService;
  late final NetworkDiscoveryService _udpService;
  late final BleAdvertiser _bleAdvertiser;
  Timer? _udpBroadcaster;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    final userModel = Provider.of<UserModel>(context, listen: false);

    // Start BLE advertising every 10 seconds
    _bleAdvertiser = BleAdvertiser(userModel);
    _bleAdvertiser.start(interval: const Duration(seconds: 10));

    // Initialize scanning services
    _bleService = BleService(
      onPeerFound: _handlePeer,
      onError: (_) => _startUdp(),
    );
    _udpService = NetworkDiscoveryService(onPeerFound: _handlePeer);
    _initDiscovery();

    // UDP presence broadcast every 10 seconds
    _udpBroadcaster = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _broadcastUdp(userModel),
    );
  }

  Future<void> _initDiscovery() async {
    _peers.clear();
    final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt ?? 0;
    if (sdk >= 31) {
      Logger().i('Starting BLE scan (SDK $sdk)');
      await _bleService.startScan();
    } else {
      Logger().i('Starting UDP discovery (SDK $sdk)');
      await _udpService.start();
    }
  }

  void _startUdp() => _udpService.start();

  void _broadcastUdp(UserModel user) {
    final self = Peer(
      instanceId: BleService.instanceId,
      displayName: user.displayName,
      status: 'available',
    );
    _udpService.sendInvite(self);
  }

  void _handlePeer(Peer peer) {
    if (!mounted) return;
    if (peer.instanceId == BleService.instanceId) return;

    if (_peers.every((p) => p.instanceId != peer.instanceId)) {
      setState(() => _peers.add(peer));
    }
  }

  @override
  void dispose() {
    _bleAdvertiser.stop();
    _bleService.stopScan();
    _udpService.dispose();
    _udpBroadcaster?.cancel();
    super.dispose();
  }

  /// Refresh the peer list by clearing and restarting discovery.
  Future<void> _onRefresh() async {
    setState(() => _peers.clear());
    _bleService.stopScan();      // no await, returns void
    _udpService.dispose();       // no await, returns void
    await _initDiscovery();      // await the actual Future
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Devices'),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            child: Text(
              user.displayName.isEmpty
                  ? 'U'
                  : user.displayName[0].toUpperCase(),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 1:
        return const Center(child: Text('Profile Screen'));  // TODO
      case 2:
        return const Center(child: Text('Settings Screen')); // TODO
      default:
        return _peers.isEmpty
            ? const Center(child: Text('No devices found'))
            : ListView.builder(
                itemCount: _peers.length,
                itemBuilder: (ctx, i) {
                  final peer = _peers[i];
                  final color = peer.status == 'available'
                      ? Colors.green
                      : peer.status == 'pending'
                          ? Colors.amber
                          : Colors.red;
                  return ListTile(
                    leading: Icon(Icons.bluetooth, color: color),
                    title: Text(peer.displayName),
                    subtitle: Text(peer.status),
                    trailing: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => showSessionInvite(
                        context,
                        peer,
                        onAccept: () =>
                            _bleService.sendInvite(peer.instanceId),
                        onDecline: () => Logger()
                            .i('Declined invite: ${peer.displayName}'),
                        onNotNow: () => Logger()
                            .i('Deferred invite: ${peer.displayName}'),
                      ),
                    ),
                  );
                },
              );
    }
  }
}
