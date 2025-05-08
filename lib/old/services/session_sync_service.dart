// lib/services/session_sync_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/session.dart'; // Ensure your Session model has toMap()

/// Handles queuing and syncing of session data to Firestore.
class SessionSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Session> _pending = [];

  /// Add a session to the pending queue.
  void queue(Session session) {
    _pending.add(session);
    Logger().i('Session queued: ${session.toMap()}');
  }

  /// Attempt to sync all pending sessions to Firestore.
  Future<void> syncAll() async {
    if (_pending.isEmpty) {
      Logger().d('No pending sessions to sync.');
      return;
    }

    // Work on a copy to avoid modification issues during iteration
    final toSync = List<Session>.from(_pending);
    for (final session in toSync) {
      try {
        await _firestore.collection('sessions').add(session.toMap());
        _pending.remove(session);
        Logger().i('Synced session: ${session.toMap()}');
      } catch (e) {
        Logger().e('Failed to sync session ${session.toMap()}: $e');
      }
    }
  }
}
