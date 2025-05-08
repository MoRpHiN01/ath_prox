// /lib/models/session_invite.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum InviteResponse { pending, accepted, declined, notNow }

class SessionInvite {
  final String deviceId;
  final String senderName;
  final DateTime timestamp;
  final InviteResponse response;

  SessionInvite({
    required this.deviceId,
    required this.senderName,
    required this.timestamp,
    this.response = InviteResponse.pending,
  });

  /// For Firebase / local storage
  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'senderName': senderName,
      'timestamp': Timestamp.fromDate(timestamp),
      'response': response.name,
    };
  }

  factory SessionInvite.fromMap(Map<String, dynamic> map) {
    return SessionInvite(
      deviceId: map['deviceId'] ?? '',
      senderName: map['senderName'] ?? 'Unknown',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      response: InviteResponse.values.firstWhere(
        (e) => e.name == map['response'],
        orElse: () => InviteResponse.pending,
      ),
    );
  }

  @override
  String toString() =>
      '[Invite] From: $senderName | $deviceId | ${response.name} at ${timestamp.toIso8601String()}';
}
