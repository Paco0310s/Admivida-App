import 'dart:io';

import 'package:admivida/common/constants/app_config.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

class ConnectivityService {
  static Future<bool> hasInternet() async {
    final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult.isEmpty) return false;

    if (connectivityResult.contains(ConnectivityResult.none)) return false;

    // En navegadores web, window.navigator.onLine (manejado por connectivity_plus)
    // ya determina la conectividad de red. Peticiones HTTP arbitrarias a dominios externos
    // (como google.com) son bloqueadas por el navegador debido a políticas de CORS.
    if (kIsWeb) return true;

    final bool internetConnection = await checkInternetConnection();

    return internetConnection;
  }

  static Future<bool> checkInternetConnection() async {
    try {
      if (kIsWeb) {
        return true;
      } else {
        // For mobile and desktop, we can use InternetAddress to check connectivity
        final result = await InternetAddress.lookup('google.com');
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isServerLive() async {
    try {
      final response = await get(Uri.parse('${AppConfig.baseUrl}/health')).timeout(const Duration(seconds: 7));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
