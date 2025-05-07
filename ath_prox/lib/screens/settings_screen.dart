// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/foreground_service_manager.dart';
import '../utils/helpers.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool debugMode = false;
  bool autoRefresh = true;
  int refreshRate = 5;
  bool backgroundServiceRunning = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      debugMode = prefs.getBool('debugMode') ?? false;
      autoRefresh = prefs.getBool('autoRefresh') ?? true;
      refreshRate = prefs.getInt('refreshRate') ?? 5;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('debugMode', debugMode);
    await prefs.setBool('autoRefresh', autoRefresh);
    await prefs.setInt('refreshRate', refreshRate);
    showToast(context, 'Settings saved');
  }

  Future<void> _resetApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    showToast(context, 'App reset complete. Restarting...');
    restartApp();
  }

Future<void> _toggleBackgroundService(bool value) async {
  if (value) {
    await ForegroundServiceManager.init();
    setState(() {
      backgroundServiceRunning = true;
    });
    showToast(context, "Service Started");
  } else {
    await ForegroundServiceManager.stop();
    setState(() {
      backgroundServiceRunning = false;
    });
    showToast(context, "Service Stopped");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("App Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            SwitchListTile(
              title: const Text("Enable Auto-Refresh"),
              subtitle: const Text("Auto refresh device list"),
              value: autoRefresh,
              onChanged: (val) {
                setState(() => autoRefresh = val);
                _saveSettings();
              },
            ),
            const SizedBox(height: 12),
            Text("Refresh Interval: $refreshRate seconds"),
            Slider(
              value: refreshRate.toDouble(),
              min: 3,
              max: 30,
              divisions: 9,
              label: refreshRate.toString(),
              onChanged: (val) => setState(() => refreshRate = val.round()),
              onChangeEnd: (_) => _saveSettings(),
            ),
            const Divider(height: 32),
            SwitchListTile(
              title: const Text("Enable Developer Mode"),
              subtitle: const Text("Show debug logs and developer tools"),
              value: debugMode,
              onChanged: (val) {
                setState(() => debugMode = val);
                _saveSettings();
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.restart_alt),
              label: const Text("Reset App"),
              onPressed: _resetApp,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(backgroundServiceRunning ? Icons.stop : Icons.play_arrow),
              label: Text(backgroundServiceRunning
                  ? "Stop Background Service"
                  : "Start Background Service"),
              onPressed: () => _toggleBackgroundService(!backgroundServiceRunning),
            ),
            if (debugMode)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Divider(),
                    Text(
                      "Developer Console",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text("TODO: Show debug logs here"),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
