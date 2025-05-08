import 'package:flutter/material.dart';

class SessionInviteButton extends StatelessWidget {
  final bool inSession;
  final VoidCallback onInvite;
  final VoidCallback onTerminate;

  const SessionInviteButton({
    Key? key,
    required this.inSession,
    required this.onInvite,
    required this.onTerminate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: inSession ? onTerminate : onInvite,
      icon: Icon(inSession ? Icons.cancel : Icons.handshake),
      label: Text(inSession ? 'End Session' : 'Invite'),
      style: ElevatedButton.styleFrom(
        backgroundColor: inSession ? Colors.red : Colors.green,
      ),
    );
  }
}