import '../models/session_record.dart';

class SessionManager {
  List<SessionRecord> _records = [];

  void startSession(String peerName) {
    _records.add(SessionRecord(peerName, DateTime.now()));
  }

  void endSession(String peerName) {
    final record = _records.lastWhere((r) => r.peerName == peerName && r.endTime == null, orElse: () => throw Exception("No session to end"));
    record.endTime = DateTime.now();
  }

  List<SessionRecord> get records => _records;
}