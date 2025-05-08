
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UUIDService {
  static const String _key = 'instance_id';

  static Future<String> getOrCreateInstanceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null) return existing;
    final newId = const Uuid().v4();
    await prefs.setString(_key, newId);
    return newId;
  }
}
