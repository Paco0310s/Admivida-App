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

    if (kIsWeb) {
      if (hasActiveAdapter) return true;
      return await isServerLive();
    }

    // En desarrollo local (Debug) con adaptador activo, operar directamente
    if (hasActiveAdapter && !kReleaseMode) {
      return true;
    }

    // 1. Verificación rápida de internet general
    if (await checkInternetConnection()) {
      return true;
    }

    // 2. Respaldo definitivo: si nuestro propio servidor responde, sí hay conexión
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
    try {
      final response = await get(Uri.parse('${AppConfig.baseUrl}/health')).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
