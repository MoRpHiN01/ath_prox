// lib/utils/firebase_utils.dart

import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

Future<void> initializeFirebaseIfNeeded() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    print("Firebase initialization error: $e");
  }
}
