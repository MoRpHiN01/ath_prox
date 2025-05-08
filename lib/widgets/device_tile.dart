import 'package:flutter/material.dart';

class DeviceTile extends StatelessWidget {
  final String name;
  final String status;

  const DeviceTile({required this.name, required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(name),
      subtitle: Text(status),
    );
  }
}
