import 'package:flutter/material.dart';

class SessionInviteBubble extends StatelessWidget {
  final String deviceName;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback? onMaybeLater;

  const SessionInviteBubble({
    super.key,
    required this.deviceName,
    required this.onAccept,
    required this.onDecline,
    this.onMaybeLater,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Session Invite"),
      content: Text("Would you like to connect with $deviceName?"),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDecline();
          },
          child: const Text("No"),
        ),
        if (onMaybeLater != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onMaybeLater!();
            },
            child: const Text("Not Now"),
          ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onAccept();
          },
          child: const Text("Sure"),
        ),
      ],
    );
  }
}
