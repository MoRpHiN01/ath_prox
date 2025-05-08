import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({Key? key}) : super(key: key);

  @override
  _AppSettingsScreenState createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _debugMode = false;
  int _refreshRate = 10;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _debugMode = prefs.getBool('debugMode') ?? false;
      _refreshRate = prefs.getInt('refreshRate') ?? 10;
    });
  }

  Future<void> _updateDebugMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('debugMode', value);
    setState(() {
      _debugMode = value;
    });
  }

  Future<void> _updateRefreshRate(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('refreshRate', value);
    setState(() {
      _refreshRate = value;
    });
  }

  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _loadSettings();
  }

  Future<void> _resetApp() async {
    await _clearStorage();
    // You can navigate to an onboarding or login screen if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Application Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Display Debug Toggle'),
              value: _debugMode,
              onChanged: _updateDebugMode,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Refresh Rate (seconds)'),
                DropdownButton<int>(
                  value: _refreshRate,
                  items: [5, 10, 15, 30]
                      .map((int value) => DropdownMenuItem<int>(
                            value: value,
                            child: Text('$value'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) _updateRefreshRate(value);
                  },
                )
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _clearStorage,
              child: const Text('Clear Local Storage'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _resetApp,
              child: const Text('Reset Application'),
            ),
          ],
        ),
      ),
    );
  }
}
