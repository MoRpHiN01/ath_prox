import 'package:flutter/material.dart';
import '../widgets/refresh_toggle.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool autoRefreshEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RefreshToggle(
          isEnabled: autoRefreshEnabled,
          onChanged: (value) {
            setState(() {
              autoRefreshEnabled = value;
              // Apply state to backend refresh service
            });
          },
        ),
      ),
    );
  }
}