import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session.dart';

class SessionSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'sessions';
  static const String _localCacheKey = 'local_sessions';

  /// Sync sessions to Firestore and cache failures
  static Future<void> syncSessions(List<Session> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> fallbackCache = prefs.getStringList(_localCacheKey) ?? [];

    for (final session in sessions) {
      final data = session.toMap();
      try {
        await _firestore.collection(_collectionName).add(data);
      } catch (e) {
        fallbackCache.add(jsonEncode(data));
      }
    }

    if (fallbackCache.isNotEmpty) {
      await prefs.setStringList(_localCacheKey, fallbackCache);
    }
  }

  /// Retry syncing cached sessions
  static Future<void> pushLocalSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> cached = prefs.getStringList(_localCacheKey) ?? [];

    final List<String> failedToSync = [];

    for (final json in cached) {
      try {
        final Map<String, dynamic> data = jsonDecode(json);
        await _firestore.collection(_collectionName).add(data);
      } catch (e) {
        failedToSync.add(json);
      }
    }

    if (failedToSync.isEmpty) {
      await prefs.remove(_localCacheKey);
    } else {
      await prefs.setStringList(_localCacheKey, failedToSync);
    }
  }

  /// Retrieve the last 100 sessions from Firestore
  static Future<List<Session>> getSyncedSessions() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('startTime', descending: true)
          .limit(100)
          .get();

      return snapshot.docs.map((doc) => Session.fromMap(doc.data())).toList();
    } catch (_) {
      return [];
    }
  }
}
