import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class SessionInviteService {
  void showSessionInvite(
    BuildContext context,
    BluetoothDevice device, {
    required VoidCallback onAccept,
    required VoidCallback onDecline,
    required VoidCallback onNotNow,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Session Invite",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Would you like to connect with ${device.platformName}?",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      Navigator.pop(context);
                      onAccept();
                    },
                    icon: const Icon(Icons.check),
                    label: const Text("Sure"),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                    onPressed: () {
                      Navigator.pop(context);
                      onNotNow();
                    },
                    icon: const Icon(Icons.access_time),
                    label: const Text("Not Now"),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      Navigator.pop(context);
                      onDecline();
                    },
                    icon: const Icon(Icons.close),
                    label: const Text("No"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
