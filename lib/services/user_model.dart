// lib/services/user_model.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserModel extends ChangeNotifier {
  String _displayName = 'User';
  bool _debugMode = false;

  String get displayName => _displayName;
  bool get debugMode => _debugMode;

  /// Load saved preferences (displayName & debugMode).
  Future<void> loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _displayName = prefs.getString('displayName') ?? 'User';
    _debugMode = prefs.getBool('debugMode') ?? false;
    notifyListeners();
  }

  /// Update and persist the user’s display name.
  Future<void> setDisplayName(String name) async {
    _displayName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('displayName', name);
    notifyListeners();
  }

  /// Enable or disable debug logging at runtime.
  Future<void> toggleDebugMode(bool value) async {
    _debugMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('debugMode', value);
    notifyListeners();
  }
}
