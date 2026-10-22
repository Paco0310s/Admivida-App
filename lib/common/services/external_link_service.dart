import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/logging/app_logger.dart';
import 'package:url_launcher/url_launcher.dart';

/// Servicio centralizado para abrir enlaces externos (sitio web de descargas,
/// portafolio personal y chat de soporte en WhatsApp).
class ExternalLinkService {
  ExternalLinkService._();

  /// Abre cualquier URL externa en el navegador predeterminado del sistema operativo.
  static Future<bool> launchWebUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        AppLogger.warning('No se pudo abrir la URL: $url');
      }
      return launched;
    } catch (error) {
      AppLogger.error('Error al intentar abrir la URL $url: $error');
      return false;
    }
  }

  /// Abre la página web oficial de Admivida para descargar versiones de Windows / Android
  /// o conocer más información sobre la plataforma.
  static Future<bool> openAdmividaWeb() async {
    return launchWebUrl(AppConfig.admividaWebUrl);
  }

  /// Abre la página web personal y portafolio de Francisco Sotelo (pacosotelo.com).
  static Future<bool> openPortfolio() async {
    return launchWebUrl(AppConfig.personalPortfolioUrl);
  }

  /// Abre WhatsApp directamente con el número de soporte y un mensaje inicial opcional.
  static Future<bool> openWhatsAppSupport({String? customMessage}) async {
    final message = Uri.encodeComponent(customMessage ?? AppConfig.supportDefaultMessage);
    final url = 'https://wa.me/${AppConfig.supportPhoneClean}?text=$message';
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        AppLogger.warning('No se pudo abrir WhatsApp con URL: $url');
      }
      return launched;
    } catch (error) {
      AppLogger.error('Error al abrir WhatsApp para soporte: $error');
      return false;
    }
  }
}

