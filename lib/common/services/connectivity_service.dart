import 'dart:convert';
import 'dart:io';

import 'package:admivida/common/constants/app_config.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

class ConnectivityService {
  static Future<bool> hasInternet() async {
    bool hasActiveAdapter = false;
    try {
      final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
      hasActiveAdapter = connectivityResult.any(
        (result) => result != ConnectivityResult.none,
      );
    } catch (_) {
      hasActiveAdapter = false;
    }

    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    if (!hasActiveAdapter && !isDesktop) {
      return false;
    }

    if (kIsWeb) {
      return await isServerLive();
    }

    // 1. Verificación rápida de salida real a internet
    if (await checkInternetConnection()) {
      return true;
    }

    // 2. Respaldo para red local (LAN/emulador sin salida externa): si nuestro propio servidor responde, sí hay conexión
    return await isServerLive();
  }

  static Future<bool> checkInternetConnection() async {
    try {
      if (kIsWeb) {
        return true;
      } else {
        final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 3));
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isServerLive() async {
    return (await fetchServerStatus()) != null;
  }

  /// Consulta `/health` y devuelve el estado del servidor (mantenimiento y versión mínima).
  /// Devuelve `null` si el servidor no responde (caído o inalcanzable).
  static Future<ServerStatus?> fetchServerStatus() async {
    try {
      final response = await get(Uri.parse('${AppConfig.baseUrl}/health')).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;

      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return ServerStatus(
            minRequiredVersionCode: (body['minRequiredVersionCode'] as num?)?.toInt() ?? 1,
            inMaintenance: body['inMaintenance'] == true,
          );
        }
      } catch (_) {
        // Servidor viejo o respuesta sin detalles: está vivo, sin restricciones.
      }
      return const ServerStatus(minRequiredVersionCode: 1, inMaintenance: false);
    } catch (e) {
      return null;
    }
  }
}

/// Estado público del servidor consultado antes de iniciar sesión.
class ServerStatus {
  final int minRequiredVersionCode;
  final bool inMaintenance;

  const ServerStatus({required this.minRequiredVersionCode, required this.inMaintenance});

  bool get requiresUpdate => minRequiredVersionCode > AppConfig.appVersionCode;
}
