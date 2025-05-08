// lib/services/firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Log a generic document to a Firestore collection
  static Future<void> logToCollection({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _db.collection(collection).add({
        ...data,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('[FIREBASE ERROR] Failed to log to $collection: $e');
      // Optionally handle retry, offline storage, etc.
    }
  }

  /// Retrieve all documents from a collection (e.g., session logs)
  static Future<List<Map<String, dynamic>>> fetchCollection(String collection) async {
    try {
      final snapshot = await _db
          .collection(collection)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('[FIREBASE ERROR] Failed to fetch from $collection: $e');
      return [];
    }
  }

  /// Delete all documents from a collection (for admin/debug tools)
  static Future<void> clearCollection(String collection) async {
    try {
      final batch = _db.batch();
      final snapshot = await _db.collection(collection).get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('[FIREBASE ERROR] Failed to clear $collection: $e');
    }
  }
}
