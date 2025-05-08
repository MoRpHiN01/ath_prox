import 'package:flutter/material.dart';

class RefreshToggle extends StatelessWidget {
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const RefreshToggle({super.key, required this.isEnabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Auto-refresh", style: TextStyle(fontSize: 16)),
        Switch(
          value: isEnabled,
          onChanged: onChanged,
        ),
      ],
    );
  }
}