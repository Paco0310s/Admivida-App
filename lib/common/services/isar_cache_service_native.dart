import 'package:admivida/common/logging/app_logger.dart';
import 'package:admivida/common/models/http_cache_entry.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

class IsarCacheService {
  static Isar? _isar;

  /// Init Isar database
  static Future<void> init() async {
    if (_isar != null && _isar!.isOpen) return;
    try {
      final existingInstance = Isar.getInstance();
      if (existingInstance != null && existingInstance.isOpen) {
        _isar = existingInstance;
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      _isar = await Isar.open([HttpCacheEntrySchema], directory: dir.path);
    } catch (e) {
      AppLogger.error('Error initializing IsarCacheService: $e');
    }
  }

  /// Save or update a JSON in the local storage
  static Future<void> saveCache(String key, String data) async {
    final isar = _isar;
    if (isar == null || !isar.isOpen) return;

    try {
      final entry = HttpCacheEntry()
        ..cacheKey = key
        ..responseData = data
        ..updatedAt = DateTime.now();

      await isar.writeTxn(() async {
        await isar.httpCacheEntrys.put(entry);
      });
    } catch (e) {
      AppLogger.warning('Error saving Isar cache for key "$key": $e');
    }
  }

  /// Search for a JSON in the local storage by its URL
  static Future<String?> getCache(String key) async {
    final isar = _isar;
    if (isar == null || !isar.isOpen) return null;

    try {
      final entry = await isar.httpCacheEntrys.where().cacheKeyEqualTo(key).findFirst();
      return entry?.responseData;
    } catch (e) {
      AppLogger.warning('Error reading Isar cache for key "$key": $e');
      return null;
    }
  }

  /// Clear all cached HTTP entries (e.g. on logout)
  static Future<void> clearCache() async {
    final isar = _isar;
    if (isar == null || !isar.isOpen) return;

    try {
      await isar.writeTxn(() async {
        await isar.httpCacheEntrys.clear();
      });
    } catch (e) {
      AppLogger.warning('Error clearing Isar cache: $e');
    }
  }
}
