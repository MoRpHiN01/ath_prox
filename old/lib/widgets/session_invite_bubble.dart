// lib/widgets/session_invite_bubble.dart

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/peer.dart';

/// Displays an invite dialog with Accept / Not Now / Decline options.
void showSessionInvite(
  BuildContext context,
  Peer peer, {
  required VoidCallback onAccept,
  required VoidCallback onDecline,
  VoidCallback? onNotNow,
}) {
  if (!context.mounted) return;

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('${peer.displayName} invites you'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            onDecline();
            Logger().i('Invite declined: ${peer.instanceId}');
          },
          child: const Text('Decline'),
        ),
        if (onNotNow != null)
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onNotNow();
              Logger().i('Invite deferred: ${peer.instanceId}');
            },
            child: const Text('Not Now'),
          ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            onAccept();
            Logger().i('Invite accepted: ${peer.instanceId}');
          },
          child: const Text('Accept'),
        ),
      ],
    ),
  );
}
