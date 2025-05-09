import 'package:flutter/material.dart';

class DeviceCard extends StatelessWidget {
  final String name;
  final String status;
  final VoidCallback onTap;

  DeviceCard({required this.name, required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(name),
        subtitle: Text("Status: $status"),
        trailing: IconButton(icon: Icon(Icons.link), onPressed: onTap),
      ),
    );
  }
}