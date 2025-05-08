import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionStateCache {
  static const _key = 'cached_session_states';

  Future<void> saveSessionStates(List<Map<String, dynamic>> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(sessions);
    await prefs.setString(_key, jsonStr);
  }

  Future<List<Map<String, dynamic>>> loadSessionStates() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(jsonStr));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}