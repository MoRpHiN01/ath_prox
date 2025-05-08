// lib/models/session.dart

class Session {
  final String peerId;
  final String peerName;
  final DateTime startTime;
  DateTime? endTime;

  Session({
    required this.peerId,
    required this.peerName,
    required this.startTime,
    this.endTime,
  });

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);

  bool get isActive => endTime == null;

  void end() {
    endTime = DateTime.now();
  }

  Map<String, dynamic> toMap() => {
        'peerId': peerId,
        'peerName': peerName,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
      };

  factory Session.fromMap(Map<String, dynamic> map) => Session(
        peerId: map['peerId'],
        peerName: map['peerName'],
        startTime: DateTime.parse(map['startTime']),
        endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      );
}
