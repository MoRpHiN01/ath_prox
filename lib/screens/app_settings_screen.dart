import 'package:flutter/material.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _debugMode = false;
  int _refreshRate = 10;

  void _clearStorage() {
    // TODO: Implement clearing local storage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Local storage cleared")),
    );
  }

  void _resetApp() {
    // TODO: Implement full application reset
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Application reset")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SwitchListTile(
              title: const Text("Display Debug Toggle"),
              value: _debugMode,
              onChanged: (value) {
                setState(() => _debugMode = value);
                // TODO: Persist debug mode flag
              },
            ),
            ListTile(
              title: const Text("Refresh Rate (seconds)"),
              subtitle: Text("$_refreshRate seconds"),
              trailing: DropdownButton<int>(
                value: _refreshRate,
                items: const [5, 10, 15, 30, 60]
                    .map((val) => DropdownMenuItem(
                          value: val,
                          child: Text("$val"),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _refreshRate = value);
                    // TODO: Persist refresh rate
                  }
                },
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text("Clear Local Storage"),
              onTap: _clearStorage,
            ),
            ListTile(
              title: const Text("Reset Application"),
              onTap: _resetApp,
            ),
          ],
        ),
      ),
    );
  }
}
