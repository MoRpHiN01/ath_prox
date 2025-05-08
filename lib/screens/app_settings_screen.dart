import 'package:flutter/material.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _debugMode = false;
  double _refreshRate = 10.0;

  void _clearStorage() {
    // Implement actual local storage clear logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Local storage cleared')),
    );
  }

  void _resetApp() {
    // Implement actual reset logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('App reset to default settings')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("App Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Display Debug Toggle"),
                Switch(
                  value: _debugMode,
                  onChanged: (value) {
                    setState(() {
                      _debugMode = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text("Auto Refresh Rate: ${_refreshRate.round()}s"),
            Slider(
              value: _refreshRate,
              min: 5,
              max: 60,
              divisions: 11,
              label: _refreshRate.round().toString(),
              onChanged: (value) {
                setState(() {
                  _refreshRate = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _clearStorage,
              child: const Text("Clear Local Storage"),
            ),
            const SizedBox(height: 10),
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