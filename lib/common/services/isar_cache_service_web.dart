import 'package:admivida/common/services/storage_service.dart';

class IsarCacheService {
  static Future<void> init() async {}

  static Future<void> saveCache(String key, String data) async {
    if (key.startsWith('offline_')) {
      try {
        await StorageService.setString('isar_web_$key', data);
      } catch (_) {}
    }
  }

  static Future<String?> getCache(String key) async {
    if (key.startsWith('offline_')) {
      try {
        return StorageService.getString('isar_web_$key');
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static Future<void> clearCache() async {}
}
