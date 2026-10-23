import 'dart:convert';
import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/logging/app_logger.dart';
import 'package:admivida/common/models/whats_new_model.dart';
import 'package:admivida/common/services/storage_service.dart';
import 'package:admivida/common/widgets/whats_new_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Servicio centralizado que gestiona las novedades de cada versión (What's New):
/// 1. Consulta el manifiesto de la versión (o usa datos del backend o caché local).
/// 2. Controla si el usuario ya vio las novedades de la versión actual en este dispositivo.
/// 3. Notifica a la campanita del inicio si hay novedades pendientes por leer.
class WhatsNewService {
  WhatsNewService._();

  /// Notificador reactivo para la campanita del AppBar
  static final ValueNotifier<bool> hasUnreadNotes = ValueNotifier<bool>(false);

  // Instancia de Dio ligera e independiente (sin interceptores de sesión)
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// Inicializa el estado de lectura al arrancar la aplicación
  static void init() {
    try {
      final lastSeen = StorageService.getInt(AppConfig.lastSeenWhatsNewVersionKey) ?? 0;
      hasUnreadNotes.value = AppConfig.appVersionCode > lastSeen;
    } catch (_) {
      hasUnreadNotes.value = false;
    }
  }

  /// Indica si corresponde mostrar el diálogo automáticamente en esta versión
  static bool shouldShowOnFirstLaunch() {
    final lastSeen = StorageService.getInt(AppConfig.lastSeenWhatsNewVersionKey) ?? 0;
    return AppConfig.appVersionCode > lastSeen;
  }

  /// Marca la versión actual como vista para no volver a mostrar el modal automáticamente
  static Future<void> markAsSeen() async {
    await StorageService.setInt(AppConfig.lastSeenWhatsNewVersionKey, AppConfig.appVersionCode);
    hasUnreadNotes.value = false;
  }

  /// Obtiene las novedades más recientes desde:
  /// 1. Datos directos del backend (si vienen en el login o perfil).
  /// 2. Manifiesto en MinIO S3 (`latest.json` o `latest-android.json`).
  /// 3. Caché local en SharedPreferences.
  /// 4. Fallback integrado en el código de la app.
  static Future<WhatsNewModel> fetchLatestWhatsNew({
    String? backendReleaseNotes,
    dynamic backendWhatsNew,
  }) async {
    // 1. Si el backend envió notas directamente
    if ((backendReleaseNotes != null && backendReleaseNotes.isNotEmpty) || backendWhatsNew != null) {
      final model = WhatsNewModel.fromJson({
        'versionCode': AppConfig.appVersionCode,
        'versionName': AppConfig.appVersionName,
        'releaseNotes': backendReleaseNotes,
        'whatsNew': backendWhatsNew,
      });
      _cacheNotes(model);
      return model;
    }

    // 2. Intentar consultar el manifiesto en la nube
    try {
      final response = await _dio.get<dynamic>(
        AppConfig.currentPlatformManifestUrl,
        queryParameters: {'t': DateTime.now().millisecondsSinceEpoch}, // Evita caché de CDN
        options: Options(responseType: ResponseType.plain),
      );

      final raw = (response.data?.toString() ?? '').replaceFirst('\uFEFF', '');
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final model = WhatsNewModel.fromJson(decoded);
        _cacheNotes(model);
        return model;
      }
    } catch (e) {
      AppLogger.info('No se pudo obtener el manifiesto remoto de novedades: $e');
    }

    // 3. Fallback a caché local guardada previamente
    final cached = StorageService.getString(AppConfig.cachedWhatsNewJsonKey);
    if (cached != null && cached.isNotEmpty) {
      try {
        final decoded = jsonDecode(cached);
        if (decoded is Map<String, dynamic>) {
          return WhatsNewModel.fromJson(decoded);
        }
      } catch (_) {}
    }

    // 4. Fallback bundled por defecto para esta versión
    return WhatsNewModel.fallback();
  }

  static void _cacheNotes(WhatsNewModel model) {
    try {
      StorageService.setString(AppConfig.cachedWhatsNewJsonKey, jsonEncode(model.toJson()));
    } catch (_) {}
  }

  /// Evalúa si es la primera vez que se abre esta versión y muestra el modal automáticamente
  static Future<void> checkAndShowOnFirstLaunch(BuildContext context) async {
    if (!shouldShowOnFirstLaunch()) return;

    // Marcamos como visto de inmediato para evitar aperturas duplicadas si hay redibujados
    await markAsSeen();

    final model = await fetchLatestWhatsNew();

    if (context.mounted && model.items.isNotEmpty) {
      WhatsNewDialog.show(context, whatsNew: model);
    }
  }

  /// Abre manualmente las novedades (por ejemplo al pulsar la campanita)
  static Future<void> showManually(BuildContext context) async {
    await markAsSeen();
    final model = await fetchLatestWhatsNew();
    if (context.mounted) {
      WhatsNewDialog.show(context, whatsNew: model);
    }
  }
}

