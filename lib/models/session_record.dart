class SessionRecord {
  final String peerName;
  final DateTime startTime;
  final DateTime? endTime;

  SessionRecord(this.peerName, this.startTime, [this.endTime]);

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);
}