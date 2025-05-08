
import 'package:flutter/material.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool debugMode = false;
  int refreshRate = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Application Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text("Enable Debug Mode"),
              value: debugMode,
              onChanged: (value) {
                setState(() {
                  debugMode = value;
                });
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Auto Refresh Rate (seconds):"),
                DropdownButton<int>(
                  value: refreshRate,
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        refreshRate = newValue;
                      });
                    }
                  },
                  items: [5, 10, 15, 30]
                      .map((rate) => DropdownMenuItem(
                            value: rate,
                            child: Text("$rate"),
                          ))
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Placeholder for clearing local storage logic
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Local storage cleared.")));
              },
              child: const Text("Clear Local Storage"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Placeholder for reset app logic
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("App reset initiated.")));
              },
              child: const Text("Reset Application"),
            ),
          ],
        ),
      ),
    );
  }
}
