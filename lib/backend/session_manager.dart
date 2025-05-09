import '../models/session.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  List<Session> activeSessions = [];

  void startSession(Session session) {
    activeSessions.add(session);
  }

  void endSession(String deviceId) {
    activeSessions.removeWhere((s) => s.deviceId == deviceId);
  }

  List<Session> getSessions() => activeSessions;
}