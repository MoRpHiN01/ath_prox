import 'package:flutter/material.dart';
import '../widgets/navigation_drawer.dart';

class DeviceListScreen extends StatelessWidget {
  const DeviceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppNavigationDrawer(),
      appBar: AppBar(
        title: const Text('Nearby Devices'),
      ),
      body: const Center(
        child: Text('Device list will appear here.'),
      ),
    );
  }
}