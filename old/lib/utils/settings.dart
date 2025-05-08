// lib/utils/settings.dart

import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  static const String _refreshKey = 'refresh_interval';
  static int refreshIntervalInSeconds = 60; // Default fallback

  /// Load refresh interval from local storage
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    refreshIntervalInSeconds = prefs.getInt(_refreshKey) ?? 60;
  }

  /// Save refresh interval to local storage
  static Future<void> setRefreshInterval(int seconds) async {
    refreshIntervalInSeconds = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_refreshKey, seconds);
  }
}
