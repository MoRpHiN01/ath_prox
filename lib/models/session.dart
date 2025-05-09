class Session {
  final String deviceId;
  final DateTime startTime;
  DateTime? endTime;

  Session({required this.deviceId, required this.startTime, this.endTime});

  Duration get duration => endTime?.difference(startTime) ?? Duration.zero;
}