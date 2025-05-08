import 'package:flutter/material.dart';
import '../services/config_service.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool debugEnabled = ConfigService.instance.debugEnabled;
  int refreshRate = ConfigService.instance.refreshRate;

  void _clearLocalStorage() async {
    await ConfigService.instance.clearAll();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Local storage cleared")),
    );
  }

  void _resetApp() async {
    await ConfigService.instance.resetApp();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("App reset")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Application Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Enable Debug Logs'),
              value: debugEnabled,
              onChanged: (value) {
                setState(() {
                  debugEnabled = value;
                  ConfigService.instance.setDebug(value);
                });
              },
            ),
            ListTile(
              title: const Text('Auto Refresh Rate (seconds)'),
              trailing: DropdownButton<int>(
                value: refreshRate,
                items: [5, 10, 15, 30].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    setState(() {
                      refreshRate = newValue;
                      ConfigService.instance.setRefreshRate(newValue);
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.cleaning_services),
              label: const Text("Clear Local Storage"),
              onPressed: _clearLocalStorage,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.restart_alt),
              label: const Text("Reset Application"),
              onPressed: _resetApp,
            ),
          ],
        ),
      ),
    );
  }
}