// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'http_cache_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetHttpCacheEntryCollection on Isar {
  IsarCollection<HttpCacheEntry> get httpCacheEntrys => this.collection();
}

const HttpCacheEntrySchema = CollectionSchema(
  name: r'HttpCacheEntry',
  id: -1867942660479566252,
  properties: {
    r'cacheKey': PropertySchema(
      id: 0,
      name: r'cacheKey',
      type: IsarType.string,
    ),
    r'responseData': PropertySchema(
      id: 1,
      name: r'responseData',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 2,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _httpCacheEntryEstimateSize,
  serialize: _httpCacheEntrySerialize,
  deserialize: _httpCacheEntryDeserialize,
  deserializeProp: _httpCacheEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'cacheKey': IndexSchema(
      id: 5885332021012296610,
      name: r'cacheKey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'cacheKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _httpCacheEntryGetId,
  getLinks: _httpCacheEntryGetLinks,
  attach: _httpCacheEntryAttach,
  version: '3.3.2',
);

int _httpCacheEntryEstimateSize(
  HttpCacheEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.cacheKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.responseData;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _httpCacheEntrySerialize(
  HttpCacheEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.cacheKey);
  writer.writeString(offsets[1], object.responseData);
  writer.writeDateTime(offsets[2], object.updatedAt);
}

HttpCacheEntry _httpCacheEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = HttpCacheEntry();
  object.cacheKey = reader.readStringOrNull(offsets[0]);
  object.id = id;
  object.responseData = reader.readStringOrNull(offsets[1]);
  object.updatedAt = reader.readDateTimeOrNull(offsets[2]);
  return object;
}

P _httpCacheEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _httpCacheEntryGetId(HttpCacheEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _httpCacheEntryGetLinks(HttpCacheEntry object) {
  return [];
}

void _httpCacheEntryAttach(
  IsarCollection<dynamic> col,
  Id id,
  HttpCacheEntry object,
) {
  object.id = id;
}

extension HttpCacheEntryByIndex on IsarCollection<HttpCacheEntry> {
  Future<HttpCacheEntry?> getByCacheKey(String? cacheKey) {
    return getByIndex(r'cacheKey', [cacheKey]);
  }

  HttpCacheEntry? getByCacheKeySync(String? cacheKey) {
    return getByIndexSync(r'cacheKey', [cacheKey]);
  }

  Future<bool> deleteByCacheKey(String? cacheKey) {
    return deleteByIndex(r'cacheKey', [cacheKey]);
  }

  bool deleteByCacheKeySync(String? cacheKey) {
    return deleteByIndexSync(r'cacheKey', [cacheKey]);
  }

  Future<List<HttpCacheEntry?>> getAllByCacheKey(List<String?> cacheKeyValues) {
    final values = cacheKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'cacheKey', values);
  }

  List<HttpCacheEntry?> getAllByCacheKeySync(List<String?> cacheKeyValues) {
    final values = cacheKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'cacheKey', values);
  }

  Future<int> deleteAllByCacheKey(List<String?> cacheKeyValues) {
    final values = cacheKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'cacheKey', values);
  }

  int deleteAllByCacheKeySync(List<String?> cacheKeyValues) {
    final values = cacheKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'cacheKey', values);
  }

  Future<Id> putByCacheKey(HttpCacheEntry object) {
    return putByIndex(r'cacheKey', object);
  }

  Id putByCacheKeySync(HttpCacheEntry object, {bool saveLinks = true}) {
    return putByIndexSync(r'cacheKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCacheKey(List<HttpCacheEntry> objects) {
    return putAllByIndex(r'cacheKey', objects);
  }

  List<Id> putAllByCacheKeySync(
    List<HttpCacheEntry> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'cacheKey', objects, saveLinks: saveLinks);
  }
}

extension HttpCacheEntryQueryWhereSort
    on QueryBuilder<HttpCacheEntry, HttpCacheEntry, QWhere> {
  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension HttpCacheEntryQueryWhere
    on QueryBuilder<HttpCacheEntry, HttpCacheEntry, QWhereClause> {
  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterWhereClause>
  cacheKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'cacheKey', value: [null]),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterWhereClause>
  cacheKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'cacheKey',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterWhereClause>
  cacheKeyEqualTo(String? cacheKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'cacheKey', value: [cacheKey]),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterWhereClause>
  cacheKeyNotEqualTo(String? cacheKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'cacheKey',
                lower: [],
                upper: [cacheKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'cacheKey',
                lower: [cacheKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'cacheKey',
                lower: [cacheKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'cacheKey',
                lower: [],
                upper: [cacheKey],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension HttpCacheEntryQueryFilter
    on QueryBuilder<HttpCacheEntry, HttpCacheEntry, QFilterCondition> {
  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  cacheKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'cacheKey'),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  cacheKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'cacheKey'),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  cacheKeyEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'cacheKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  cacheKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'cacheKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  cacheKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'cacheKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  cacheKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'cacheKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  cacheKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'cacheKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  cacheKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'cacheKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  cacheKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'cacheKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  cacheKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'cacheKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  cacheKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'cacheKey', value: ''),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  cacheKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'cacheKey', value: ''),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  responseDataIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'responseData'),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  responseDataIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'responseData'),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  responseDataEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'responseData',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  responseDataGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'responseData',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  responseDataLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'responseData',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  responseDataBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'responseData',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  responseDataStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'responseData',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  responseDataEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'responseData',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  responseDataContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'responseData',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  responseDataMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'responseData',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  responseDataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'responseData', value: ''),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  responseDataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'responseData', value: ''),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'updatedAt'),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'updatedAt'),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  updatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  updatedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  updatedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterFilterCondition>
  updatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension HttpCacheEntryQueryObject
    on QueryBuilder<HttpCacheEntry, HttpCacheEntry, QFilterCondition> {}

extension HttpCacheEntryQueryLinks
    on QueryBuilder<HttpCacheEntry, HttpCacheEntry, QFilterCondition> {}

extension HttpCacheEntryQuerySortBy
    on QueryBuilder<HttpCacheEntry, HttpCacheEntry, QSortBy> {
  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterSortBy> sortByCacheKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheKey', Sort.asc);
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterSortBy>
  sortByCacheKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheKey', Sort.desc);
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterSortBy>
  sortByResponseData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'responseData', Sort.asc);
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterSortBy>
  sortByResponseDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'responseData', Sort.desc);
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension HttpCacheEntryQuerySortThenBy
    on QueryBuilder<HttpCacheEntry, HttpCacheEntry, QSortThenBy> {
  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterSortBy> thenByCacheKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheKey', Sort.asc);
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterSortBy>
  thenByCacheKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheKey', Sort.desc);
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterSortBy>
  thenByResponseData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'responseData', Sort.asc);
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterSortBy>
  thenByResponseDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'responseData', Sort.desc);
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension HttpCacheEntryQueryWhereDistinct
    on QueryBuilder<HttpCacheEntry, HttpCacheEntry, QDistinct> {
  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QDistinct> distinctByCacheKey({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cacheKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QDistinct>
  distinctByResponseData({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'responseData', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<HttpCacheEntry, HttpCacheEntry, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension HttpCacheEntryQueryProperty
    on QueryBuilder<HttpCacheEntry, HttpCacheEntry, QQueryProperty> {
  QueryBuilder<HttpCacheEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<HttpCacheEntry, String?, QQueryOperations> cacheKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cacheKey');
    });
  }

  QueryBuilder<HttpCacheEntry, String?, QQueryOperations>
  responseDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'responseData');
    });
  }

  QueryBuilder<HttpCacheEntry, DateTime?, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
