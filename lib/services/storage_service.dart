// lib/services/storage_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _keyDisplayName = 'display_name';
  static const _keyAutoRefreshInterval = 'auto_refresh_interval';
  static const _keyDebugMode = 'debug_mode';
  static const _keyAdvertising = 'is_advertising';
  static const _keyTotalSessionSeconds = 'total_session_seconds';
  static const _keySessionHistory = 'session_history';

  static Future<void> saveDisplayName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDisplayName, name);
  }

  static Future<String?> getDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDisplayName);
  }

  static Future<void> saveAutoRefreshInterval(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAutoRefreshInterval, seconds);
  }

  static Future<int> getAutoRefreshInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyAutoRefreshInterval) ?? 10;
  }

  static Future<void> saveDebugMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDebugMode, enabled);
  }

  static Future<bool> getDebugMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDebugMode) ?? false;
  }

  static Future<void> saveAdvertisingStatus(bool isAdvertising) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAdvertising, isAdvertising);
  }

  static Future<bool> getAdvertisingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAdvertising) ?? false;
  }

  static Future<void> saveTotalSessionSeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTotalSessionSeconds, seconds);
  }

  static Future<int> getTotalSessionSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTotalSessionSeconds) ?? 0;
  }

  static Future<void> saveSessionHistory(List<String> sessionsJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keySessionHistory, sessionsJson);
  }

  static Future<List<String>> getSessionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keySessionHistory) ?? [];
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
