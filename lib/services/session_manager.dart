import 'dart:collection';
import '../models/peer.dart';

class SessionManager {
  final Map<String, DateTime> _activeSessions = HashMap();

  void startSession(Peer peer) {
    _activeSessions[peer.instanceId] = DateTime.now();
  }

  void endSession(String instanceId) {
    _activeSessions.remove(instanceId);
  }

  bool isInSessionWith(String instanceId) {
    return _activeSessions.containsKey(instanceId);
  }

  Duration? sessionDuration(String instanceId) {
    if (_activeSessions.containsKey(instanceId)) {
      return DateTime.now().difference(_activeSessions[instanceId]!);
    }
    return null;
  }
}