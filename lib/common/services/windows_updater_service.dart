import 'dart:convert';
import 'dart:io';

import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/logging/app_logger.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Información de la última versión publicada (`latest.json` en Windows o `latest-android.json` en Android).
class AppUpdateInfo {
  final int versionCode;
  final String versionName;
  final String downloadUrl;
  final String? sha256;
  final bool mandatory;
  final String? releaseNotes;

  const AppUpdateInfo({
    required this.versionCode,
    required this.versionName,
    required this.downloadUrl,
    this.sha256,
    this.mandatory = false,
    this.releaseNotes,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    final rawUrl = (json['downloadUrl'] as String?)?.trim();
    final defaultUrl = Platform.isAndroid ? AppConfig.androidApkUrl : AppConfig.windowsInstallerUrl;

    final String resolvedUrl;
    if (rawUrl == null || rawUrl.isEmpty) {
      resolvedUrl = defaultUrl;
    } else if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      resolvedUrl = rawUrl;
    } else {
      // Permite rutas relativas en el manifiesto (ej. "/releases/Admivida.apk")
      resolvedUrl = '${AppConfig.minioPublicUrl}${rawUrl.startsWith('/') ? '' : '/'}$rawUrl';
    }

    return AppUpdateInfo(
      versionCode: (json['versionCode'] as num?)?.toInt() ?? 0,
      versionName: json['versionName']?.toString() ?? '',
      downloadUrl: resolvedUrl,
      sha256: (json['sha256'] as String?)?.trim(),
      mandatory: json['mandatory'] == true,
      releaseNotes: (json['releaseNotes'] as String?)?.trim(),
    );
  }

  /// Info de respaldo cuando no se pudo leer el manifiesto pero el backend exige actualizar.
  factory AppUpdateInfo.fallbackMandatory() => AppUpdateInfo(
        versionCode: 0,
        versionName: 'más reciente',
        downloadUrl: Platform.isAndroid ? AppConfig.androidApkUrl : AppConfig.windowsInstallerUrl,
        mandatory: true,
      );
}

/// Alias para mantener retrocompatibilidad con código existente
typedef WindowsUpdateInfo = AppUpdateInfo;

/// Servicio unificado de auto-actualización para Windows y Android (MinIO S3):
/// 1. Consulta el manifiesto (`latest.json` en Windows o `latest-android.json` en Android).
/// 2. Descarga el paquete (`.exe` en Windows o `.apk` en Android), verificando su SHA-256.
/// 3. Ejecuta la instalación correspondiente según la plataforma.
class AppUpdaterService {
  AppUpdaterService._();

  /// Versión que el usuario pospuso con "Más tarde" durante esta sesión.
  static int? _dismissedVersionCode;

  static bool get isSupported => !kIsWeb && (Platform.isWindows || Platform.isAndroid);

  // Dio independiente (sin token, sin caché Isar, sin interceptores de sesión)
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  static String get _manifestUrl {
    if (Platform.isAndroid) return AppConfig.androidUpdateManifestUrl;
    return AppConfig.windowsUpdateManifestUrl;
  }

  /// Devuelve la actualización disponible o `null` si ya se tiene la última versión
  /// (o si no fue posible consultar MinIO).
  static Future<AppUpdateInfo?> checkForUpdate({bool ignoreDismissed = false}) async {
    if (!isSupported) return null;

    try {
      final response = await _dio.get<dynamic>(
        _manifestUrl,
        queryParameters: {'t': DateTime.now().millisecondsSinceEpoch}, // Evita caché de proxies/CDN
        options: Options(responseType: ResponseType.plain),
      );

      final raw = (response.data?.toString() ?? '').replaceFirst('\uFEFF', '');
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;

      final info = AppUpdateInfo.fromJson(Map<String, dynamic>.from(decoded));
      if (info.versionCode <= AppConfig.appVersionCode) return null;
      if (!info.mandatory && !ignoreDismissed && _dismissedVersionCode == info.versionCode) return null;

      AppLogger.info('Actualización disponible (${Platform.operatingSystem}): ${info.versionName} (${info.versionCode})');
      return info;
    } catch (e) {
      AppLogger.warning('No se pudo consultar actualizaciones (${Platform.operatingSystem}): $e');
      return null;
    }
  }

  /// Marca la versión como pospuesta para no volver a mostrarla en esta sesión.
  static void dismiss(AppUpdateInfo info) {
    _dismissedVersionCode = info.versionCode;
  }

  /// Descarga el paquete de instalación (EXE o APK) y valida su integridad con SHA-256.
  /// [onProgress] recibe valores entre 0.0 y 1.0, o `null` si el servidor no envía el tamaño.
  static Future<File> downloadInstaller(
    AppUpdateInfo info, {
    void Function(double? progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final extension = Platform.isAndroid ? 'apk' : 'exe';
    final prefix = Platform.isAndroid ? 'Admivida' : 'AdmividaSetup';
    final file = File('${tempDir.path}${Platform.pathSeparator}${prefix}_${info.versionCode}.$extension');

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
        throw Exception('El archivo descargado está incompleto o fue modificado. Intenta de nuevo.');
      }
    }

    return file;
  }

  /// Ejecuta el instalador según la plataforma:
  /// - En Windows: ejecuta el instalador silencioso en proceso desacoplado y cierra la app.
  /// - En Android: solicita permiso si es necesario y abre el instalador de paquetes nativo del sistema.
  static Future<void> launchInstallerAndExit(File installer) async {
    if (Platform.isWindows) {
      await Process.start(
        installer.path,
        ['/SILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/CLOSEAPPLICATIONS'],
        mode: ProcessStartMode.detached,
      );
      exit(0);
    } else if (Platform.isAndroid) {
      // Verificar permiso para instalar aplicaciones de fuentes desconocidas
      final status = await Permission.requestInstallPackages.status;
      if (!status.isGranted) {
        final requested = await Permission.requestInstallPackages.request();
        if (!requested.isGranted) {
          throw Exception(
            'Debes autorizar la instalación de aplicaciones en los Ajustes de Android para poder actualizar Admivida.',
          );
        }
      }

      final result = await OpenFilex.open(
        installer.path,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done) {
        throw Exception('No se pudo abrir el instalador del APK: ${result.message}');
      }
    }
  }
}

/// Alias para mantener retrocompatibilidad total con llamadas previas
typedef WindowsUpdaterService = AppUpdaterService;
