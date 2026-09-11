import 'package:isar_community/isar.dart';

part 'http_cache_entry.g.dart';

@collection
class HttpCacheEntry {
  Id id = Isar.autoIncrement;

  // The URL that already exists, it will overwrite the old one instead of duplicating it.
  @Index(unique: true, replace: true)
  String? cacheKey;

  String? responseData;

  DateTime? updatedAt; // Useful for cache expiration logic if needed in the future.
}
