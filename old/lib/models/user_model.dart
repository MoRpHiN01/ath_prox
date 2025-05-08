// lib/models/user_model.dart

import 'dart:io';
import 'package:flutter/foundation.dart';

class UserModel extends ChangeNotifier {
  String _displayName = 'User';
  String? _email;
  File? _profileImage;

  String get displayName => _displayName;
  String? get email => _email;
  File? get profileImage => _profileImage;

  // If needed for asset/image rendering
  String get profileImagePath => _profileImage?.path ?? "";

  void updateDisplayName(String newName) {
    _displayName = newName;
    notifyListeners();
  }

  void updateEmail(String? newEmail) {
    _email = newEmail;
    notifyListeners();
  }

  void updateProfileImage(File? image) {
    _profileImage = image;
    notifyListeners();
  }

  void reset() {
    _displayName = 'User';
    _email = null;
    _profileImage = null;
    notifyListeners();
  }
}