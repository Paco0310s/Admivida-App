import 'dart:convert';

import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/logging/app_logger.dart';
import 'package:admivida/common/models/user_logged_model.dart';
import 'package:admivida/common/services/storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio dedicado exclusivamente a datos sensibles y de sesión del usuario
/// respaldado por [FlutterSecureStorage] con caché en memoria para lecturas síncronas.
class SecureStorageService {
  SecureStorageService._();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static const Set<String> _managedKeys = {
    AppConfig.accessTokenKey,
    AppConfig.refreshTokenKey,
    AppConfig.uuidKey,
    AppConfig.rolesKey,
    AppConfig.currentPlatformRoleKey,
    AppConfig.userBusinessesRolesKey,
  };

  static final Map<String, String> _values = {};

  static Future<void> init() async {
    for (final key in _managedKeys) {
      String? value;
      try {
        value = await _secureStorage.read(key: key);
      } catch (e) {
        AppLogger.warning('Error reading key "$key" from SecureStorage, resetting key: $e');
        try {
          await _secureStorage.delete(key: key);
        } catch (_) {}
        value = null;
      }

      // Migración automática única si algún dato de sesión estaba en SharedPreferences
      if (value == null && StorageService.containsKey(key)) {
        value = StorageService.getString(key);
        if (value != null) {
          try {
            await _secureStorage.write(key: key, value: value);
            await StorageService.remove(key);
          } catch (e) {
            AppLogger.warning('Error migrating key "$key" to SecureStorage: $e');
          }
        }
      }

      if (value != null) {
        _values[key] = value;
      }
    }
  }

  static Future<bool> setString(String key, String value) async {
    _values[key] = value;
    try {
      await _secureStorage.write(key: key, value: value);
      return true;
    } catch (e) {
      AppLogger.error('Error writing key "$key" to SecureStorage: $e');
      return false;
    }
  }

  static String? getString(String key) {
    return _values[key];
  }

  static Future<bool> setJson(String key, Map<String, dynamic> value) async {
    return await setString(key, jsonEncode(value));
  }

  static Map<String, dynamic>? getJson(String key) {
    final jsonString = getString(key);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> remove(String key) async {
    _values.remove(key);
    try {
      await _secureStorage.delete(key: key);
      return true;
    } catch (e) {
      AppLogger.warning('Error deleting key "$key" from SecureStorage: $e');
      return false;
    }
  }

  static Future<void> clear() async {
    final keysToDelete = {..._managedKeys, ..._values.keys};
    _values.clear();
    await Future.wait(
      keysToDelete.map((key) async {
        try {
          await _secureStorage.delete(key: key);
        } catch (_) {}
      }),
    );
  }

  static bool containsKey(String key) {
    return _values.containsKey(key);
  }

  /// Guarda toda la información de sesión del usuario autenticado (tokens, uuid, roles de plataforma y roles por negocio).
  static Future<void> saveUserSession(UserLoggedModel userData) async {
    if (userData.accessToken.isNotEmpty) {
      await setString(AppConfig.accessTokenKey, userData.accessToken);
    }
    if (userData.refreshToken.isNotEmpty) {
      await setString(AppConfig.refreshTokenKey, userData.refreshToken);
    }
    await setString(AppConfig.uuidKey, userData.userId);
    await setString(AppConfig.rolesKey, userData.roles.join(','));
    await saveUserBusinessesRoles(userData.businesses);
  }

  /// Guarda la lista de negocios y sus respectivos `business_roles` del usuario.
  static Future<void> saveUserBusinessesRoles(List<BusinessModel> businesses) async {
    await setString(
      AppConfig.userBusinessesRolesKey,
      jsonEncode(businesses.map((b) => b.toJson()).toList()),
    );
  }

  /// Actualiza o agrega los roles de un negocio específico en el almacenamiento seguro.
  static Future<void> upsertBusinessRoles(String businessId, List<String> roles) async {
    final raw = getString(AppConfig.userBusinessesRolesKey);
    final List<Map<String, dynamic>> currentList = [];

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              currentList.add(Map<String, dynamic>.from(item));
            }
          }
        }
      } catch (_) {}
    }

    final normalizedRoles = roles.map((r) => r.trim().toUpperCase()).where((r) => r.isNotEmpty).toSet().toList();
    final existingIndex = currentList.indexWhere((item) => item['businessId'] == businessId);
    if (existingIndex >= 0) {
      currentList[existingIndex] = {
        'businessId': businessId,
        'business_roles': normalizedRoles,
      };
    } else {
      currentList.add({
        'businessId': businessId,
        'business_roles': normalizedRoles,
      });
    }

    await setString(AppConfig.userBusinessesRolesKey, jsonEncode(currentList));
  }

  /// Obtiene la lista de roles que tiene el usuario actual dentro del negocio [businessId] (ej. `['SELLER']` o `['ADMIN', 'SELLER']`).
  static List<String> getBusinessRoles(String businessId) {
    final raw = getString(AppConfig.userBusinessesRolesKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map<String, dynamic> && item['businessId'] == businessId) {
            final rawRoles = item['business_roles'] ?? item['businessRoles'] ?? item['roles'];
            if (rawRoles is List) {
              return rawRoles
                  .map((e) => e.toString().trim().toUpperCase())
                  .where((r) => r.isNotEmpty)
                  .toList();
            }
          }
        }
      }
    } catch (_) {}

    return const [];
  }

  /// Devuelve `true` únicamente si el usuario tiene rol de Administrador en el negocio [businessId].
  static bool isBusinessAdmin(String businessId) {
    final roles = getBusinessRoles(businessId);
    return roles.any(
      (role) =>
          role == 'ADMIN' ||
          role == 'ADMINISTRADOR' ||
          role == 'OWNER' ||
          role.contains('ADMIN'),
    );
  }
}

