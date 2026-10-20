import 'dart:convert';
import 'dart:io';

import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/logging/app_logger.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Información de la última versión publicada para Windows (`latest.json`).
class WindowsUpdateInfo {
  final int versionCode;
  final String versionName;
  final String downloadUrl;
  final String? sha256;
  final bool mandatory;
  final String? releaseNotes;

  const WindowsUpdateInfo({
    required this.versionCode,
    required this.versionName,
    required this.downloadUrl,
    this.sha256,
    this.mandatory = false,
    this.releaseNotes,
  });

  factory WindowsUpdateInfo.fromJson(Map<String, dynamic> json) {
    final rawUrl = (json['downloadUrl'] as String?)?.trim();
    final String resolvedUrl;
    if (rawUrl == null || rawUrl.isEmpty) {
      resolvedUrl = AppConfig.windowsInstallerUrl;
    } else if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      resolvedUrl = rawUrl;
    } else {
      // Permite rutas relativas en el manifiesto (ej. "/releases/AdmividaSetup.exe")
      resolvedUrl = '${AppConfig.minioPublicUrl}${rawUrl.startsWith('/') ? '' : '/'}$rawUrl';
    }

    return WindowsUpdateInfo(
      versionCode: (json['versionCode'] as num?)?.toInt() ?? 0,
      versionName: json['versionName']?.toString() ?? '',
      downloadUrl: resolvedUrl,
      sha256: (json['sha256'] as String?)?.trim(),
      mandatory: json['mandatory'] == true,
      releaseNotes: (json['releaseNotes'] as String?)?.trim(),
    );
  }

  /// Info de respaldo cuando no se pudo leer el manifiesto pero el backend exige actualizar.
  factory WindowsUpdateInfo.fallbackMandatory() => const WindowsUpdateInfo(
        versionCode: 0,
        versionName: 'más reciente',
        downloadUrl: AppConfig.windowsInstallerUrl,
        mandatory: true,
      );
}

/// Servicio de auto-actualización para Windows:
/// 1. Consulta `latest.json` en el servidor.
/// 2. Descarga el instalador `AdmividaSetup.exe` (verificando su SHA-256).
/// 3. Lanza el instalador en modo silencioso y cierra la app; el instalador la vuelve a abrir.
class WindowsUpdaterService {
  WindowsUpdaterService._();

  /// Versión que el usuario pospuso con "Más tarde" durante esta sesión.
  static int? _dismissedVersionCode;

  static bool get isSupported => !kIsWeb && Platform.isWindows;

  // Dio independiente (sin token, sin caché Isar, sin interceptores de sesión)
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  /// Devuelve la actualización disponible o `null` si ya se tiene la última versión
  /// (o si no fue posible consultar el servidor).
  static Future<WindowsUpdateInfo?> checkForUpdate({bool ignoreDismissed = false}) async {
    if (!isSupported) return null;

    try {
      final response = await _dio.get<dynamic>(
        AppConfig.windowsUpdateManifestUrl,
        queryParameters: {'t': DateTime.now().millisecondsSinceEpoch}, // Evita caché de proxies/CDN
        options: Options(responseType: ResponseType.plain),
      );

      final raw = (response.data?.toString() ?? '').replaceFirst('\uFEFF', '');
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;

      final info = WindowsUpdateInfo.fromJson(Map<String, dynamic>.from(decoded));
      if (info.versionCode <= AppConfig.appVersionCode) return null;
      if (!info.mandatory && !ignoreDismissed && _dismissedVersionCode == info.versionCode) return null;

      AppLogger.info('Actualización de Windows disponible: ${info.versionName} (${info.versionCode})');
      return info;
    } catch (e) {
      AppLogger.warning('No se pudo consultar actualizaciones de Windows: $e');
      return null;
    }
  }

  /// Marca la versión como pospuesta para no volver a mostrarla en esta sesión.
  static void dismiss(WindowsUpdateInfo info) {
    _dismissedVersionCode = info.versionCode;
  }

  /// Descarga el instalador al directorio temporal y valida su integridad.
  /// [onProgress] recibe valores entre 0.0 y 1.0, o `null` si el servidor no envía el tamaño.
  static Future<File> downloadInstaller(
    WindowsUpdateInfo info, {
    void Function(double? progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}${Platform.pathSeparator}AdmividaSetup_${info.versionCode}.exe');

    if (await file.exists()) {
      await file.delete();
    }

    await _dio.download(
      info.downloadUrl,
      file.path,
      cancelToken: cancelToken,
      queryParameters: {'t': DateTime.now().millisecondsSinceEpoch},
      onReceiveProgress: (received, total) {
        onProgress?.call(total > 0 ? received / total : null);
      },
    );

    final expectedHash = info.sha256;
    if (expectedHash != null && expectedHash.isNotEmpty) {
      final digest = await crypto.sha256.bind(file.openRead()).first;
      if (digest.toString().toLowerCase() != expectedHash.toLowerCase()) {
        await file.delete();
        throw Exception('El instalador descargado está incompleto o fue modificado. Intenta de nuevo.');
      }
    }

    return file;
  }

  /// Ejecuta el instalador en modo silencioso (solo muestra la barra de progreso) y cierra la app.
  /// El instalador reemplaza los archivos y vuelve a abrir Admivida automáticamente.
  static Future<void> launchInstallerAndExit(File installer) async {
    await Process.start(
      installer.path,
      ['/SILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/CLOSEAPPLICATIONS'],
      mode: ProcessStartMode.detached,
    );
    exit(0);
  }
}

