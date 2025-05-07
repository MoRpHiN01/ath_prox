// lib/widgets/device_list_item.dart

import 'package:flutter/material.dart';

class DeviceListItem extends StatelessWidget {
  final String deviceName;
  final String deviceId;
  final String status;
  final VoidCallback onInvite;
  final VoidCallback? onDisconnect;

  const DeviceListItem({
    super.key,
    required this.deviceName,
    required this.deviceId,
    required this.status,
    required this.onInvite,
    this.onDisconnect,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'connected':
        return Colors.blue;
      case 'pending':
        return Colors.amber;
      case 'declined':
        return Colors.red;
      case 'lost':
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = status.toLowerCase() == "connected";

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getStatusColor(status),
        radius: 8,
      ),
      title: Text(deviceName),
      subtitle: Text('$deviceId\nStatus: $status'),
      trailing: ElevatedButton(
        onPressed: isConnected ? onDisconnect : onInvite,
        style: ElevatedButton.styleFrom(
          backgroundColor: isConnected ? Colors.blueGrey : null,
        ),
        child: Text(isConnected ? "In Session" : "Invite"),
      ),
    );
  }
}
