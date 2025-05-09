import 'package:flutter/material.dart';

class DeviceTile extends StatelessWidget {
  final dynamic device;

  const DeviceTile({required this.device});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(device['name'] ?? 'Unknown Device'),
      subtitle: Text("Status: ${device['status']}"),
      trailing: ElevatedButton(
        child: Text(device['inSession'] ? 'End' : 'Invite'),
        onPressed: () {
          // TODO: Handle invite/end session logic
        },
      ),
    );
  }
}