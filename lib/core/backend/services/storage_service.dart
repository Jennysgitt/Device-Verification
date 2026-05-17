import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._();
  static final StorageService _instance = StorageService._();
  static StorageService get instance => _instance;

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get _preferences async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  Future<void> setString(String key, String value) async {
    final prefs = await _preferences;
    await prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs?.getString(key);
  }

  Future<void> setBool(String key, bool value) async {
    final prefs = await _preferences;
    await prefs.setBool(key, value);
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return _prefs?.getBool(key) ?? defaultValue;
  }

  Future<void> setInt(String key, int value) async {
    final prefs = await _preferences;
    await prefs.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  Future<void> remove(String key) async {
    final prefs = await _preferences;
    await prefs.remove(key);
  }

  Future<void> clear() async {
    final prefs = await _preferences;
    await prefs.clear();
  }
}

