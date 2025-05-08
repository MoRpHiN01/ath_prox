
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showDebug = false;
  int _refreshRate = 10;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showDebug = prefs.getBool('showDebug') ?? false;
      _refreshRate = prefs.getInt('refreshRate') ?? 10;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showDebug', _showDebug);
    await prefs.setInt('refreshRate', _refreshRate);
  }

  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Local storage cleared.')),
    );
  }

  void _resetApp() {
    // Placeholder for app reset logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('App reset triggered.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SwitchListTile(
              title: const Text("Show Debug Toggle"),
              value: _showDebug,
              onChanged: (val) {
                setState(() => _showDebug = val);
                _saveSettings();
              },
            ),
            ListTile(
              title: const Text("Refresh Rate (seconds)"),
              trailing: DropdownButton<int>(
                value: _refreshRate,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _refreshRate = val);
                    _saveSettings();
                  }
                },
                items: [5, 10, 15, 30, 60]
                    .map((rate) => DropdownMenuItem(
                          value: rate,
                          child: Text('$rate'),
                        ))
                    .toList(),
              ),
            ),
            const Divider(),
            ElevatedButton(
              onPressed: _clearStorage,
              child: const Text("Clear Local Storage"),
            ),
            ElevatedButton(
              onPressed: _resetApp,
              child: const Text("Reset Application"),
            ),
          ],
        ),
      ),
    );
  }
}
