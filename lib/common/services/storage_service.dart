import 'package:admivida/common/logging/app_logger.dart';
import 'package:admivida/common/constants/app_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static SharedPreferences? _prefs;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const Set<String> _secureKeys = {
    AppConfig.accessTokenKey,
    AppConfig.refreshTokenKey,
  };
  static final Map<String, String> _secureValues = {};

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    for (final key in _secureKeys) {
      var value = await _secureStorage.read(key: key);
      if (value == null) {
        value = _prefs!.getString(key);
        if (value != null) {
          await _secureStorage.write(key: key, value: value);
          await _prefs!.remove(key);
        }
      }

      if (value != null) _secureValues[key] = value;
    }
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      AppLogger.error('StorageService not initialized. Call init() first.');
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // String methods
  static Future<bool> setString(String key, String value) async {
    if (_secureKeys.contains(key)) {
      await _secureStorage.write(key: key, value: value);
      _secureValues[key] = value;
      return true;
    }
    return await prefs.setString(key, value);
  }

  static String? getString(String key) {
    if (_secureKeys.contains(key)) return _secureValues[key];
    return prefs.getString(key);
  }

  // int methods
  static Future<bool> setInt(String key, int value) async {
    return await prefs.setInt(key, value);
  }

  static int? getInt(String key) {
    return prefs.getInt(key);
  }

  // JSON methods
  static Future<bool> setJson(String key, Map<String, dynamic> value) async {
    return await setString(key, jsonEncode(value));
  }

  static Map<String, dynamic>? getJson(String key) {
    final jsonString = getString(key);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // Remove methods
  static Future<bool> remove(String key) async {
    if (_secureKeys.contains(key)) {
      _secureValues.remove(key);
      await _secureStorage.delete(key: key);
      await prefs.remove(key);
      return true;
    }
    return await prefs.remove(key);
  }

  static Future<bool> clear() async {
    _secureValues.clear();
    final preferencesCleared = await prefs.clear();
    await Future.wait(_secureKeys.map((key) => _secureStorage.delete(key: key)));
    return preferencesCleared;
  }

  // Check if key exists
  static bool containsKey(String key) {
    if (_secureKeys.contains(key)) return _secureValues.containsKey(key);
    return prefs.containsKey(key);
  }
}
