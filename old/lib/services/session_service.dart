// lib/services/session_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/session.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  final List<Session> _sessions = [];

  Future<void> init() async {
    await _loadSessions();
  }

  List<Session> get allSessions => _sessions;

  void startSession(String peerId, String peerName) {
    final existing = _sessions.where((s) => s.peerId == peerId && s.isActive);
    if (existing.isEmpty) {
      final newSession = Session(
        peerId: peerId,
        peerName: peerName,
        startTime: DateTime.now(),
      );
      _sessions.add(newSession);
      _saveSessions();
    }
  }

  void endSession(String peerId) {
    for (final session in _sessions) {
      if (session.peerId == peerId && session.isActive) {
        session.end();
      }
    }
    _saveSessions();
  }

  Duration get totalSessionTime {
    return _sessions.fold(Duration.zero, (acc, s) => acc + s.duration);
  }

  Future<void> clearSessions() async {
    _sessions.clear();
    await _saveSessions();
  }

  Future<void> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('sessions');
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _sessions.clear();
      _sessions.addAll(list.map((e) => Session.fromMap(e)));
    }
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_sessions.map((s) => s.toMap()).toList());
    await prefs.setString('sessions', encoded);
  }
}
