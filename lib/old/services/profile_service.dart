// lib/services/profile_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static const String _keyDisplayName = 'displayName';

  /// Retrieves the saved display name, or null if not set.
  static Future<String?> getDisplayName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyDisplayName);
    } catch (e) {
      // Optional: log or handle error
      return null;
    }
  }

  /// Saves the display name to local preferences.
  static Future<void> setDisplayName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDisplayName, name);
  }
}
