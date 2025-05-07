// lib/models/session.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionStatus { pending, accepted, declined, completed }

class Session {
  final String sessionId;
  final String deviceId;
  final String deviceName;
  final DateTime startTime;
  final DateTime? endTime;
  final SessionStatus status;

  Session({
    required this.sessionId,
    required this.deviceId,
    required this.deviceName,
    required this.startTime,
    this.endTime,
    this.status = SessionStatus.pending,
  });

  Duration get duration => endTime != null ? endTime!.difference(startTime) : Duration.zero;

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'status': status.name,
      'duration': duration.inSeconds,
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      sessionId: map['sessionId'] ?? '',
      deviceId: map['deviceId'] ?? '',
      deviceName: map['deviceName'] ?? 'Unknown',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: map['endTime'] != null ? (map['endTime'] as Timestamp).toDate() : null,
      status: SessionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SessionStatus.pending,
      ),
    );
  }

  Session copyWithEndedNow() {
    return Session(
      sessionId: sessionId,
      deviceId: deviceId,
      deviceName: deviceName,
      startTime: startTime,
      endTime: DateTime.now(),
      status: SessionStatus.completed,
    );
  }
}
