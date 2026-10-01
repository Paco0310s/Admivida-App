import 'package:admivida/common/models/http_cache_entry.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

class IsarCacheService {
  static late Isar _isar;

  /// Init Isar database
  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open([HttpCacheEntrySchema], directory: dir.path);
  }

  /// Save or update a JSON in the local storage
  static Future<void> saveCache(String key, String data) async {
    final entry = HttpCacheEntry()
      ..cacheKey = key
      ..responseData = data
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.httpCacheEntrys.put(entry);
    });
  }

  /// Search for a JSON in the local storage by its URL
  static Future<String?> getCache(String key) async {
    final entry = await _isar.httpCacheEntrys.where().cacheKeyEqualTo(key).findFirst();

    return entry?.responseData;
  }
}
