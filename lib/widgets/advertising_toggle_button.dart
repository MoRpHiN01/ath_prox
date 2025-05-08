import 'package:flutter/material.dart';

class AdvertisingToggleButton extends StatelessWidget {
  final bool isAdvertising;
  final VoidCallback onToggle;

  const AdvertisingToggleButton({
    Key? key,
    required this.isAdvertising,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onToggle,
      icon: Icon(
        isAdvertising ? Icons.bluetooth_disabled : Icons.bluetooth_searching,
      ),
      label: Text(isAdvertising ? 'Stop Advertising' : 'Start Advertising'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isAdvertising ? Colors.redAccent : Colors.green,
      ),
    );
  }
}
