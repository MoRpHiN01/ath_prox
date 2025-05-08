class SessionState {
  final String peerId;
  final DateTime startTime;
  DateTime? endTime;

  SessionState({
    required this.peerId,
    required this.startTime,
    this.endTime,
  });

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);
}