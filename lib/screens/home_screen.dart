import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Devices')),
      body: const Center(child: Text('Device list will appear here.')),
      drawer: Drawer(
        child: ListView(
          children: const [
            DrawerHeader(
              child: Text('ATH PROXIMITY'),
            ),
            ListTile(
              title: Text('Profile'),
            ),
            ListTile(
              title: Text('Settings'),
            ),
            ListTile(
              title: Text('Reports'),
            ),
            ListTile(
              title: Text('About'),
            ),
          ],
        ),
      ),
    );
  }
}
