import 'package:admivida/common/constants/app_assets.dart';
import 'package:admivida/common/services/external_link_service.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Botón flotante estilizado con la identidad oficial de WhatsApp
/// para contactar directamente al soporte técnico.
class FloatingWhatsAppButton extends StatelessWidget {
  const FloatingWhatsAppButton({
    super.key,
    this.customMessage,
    this.extended = false,
    this.tooltip = 'Contactar soporte por WhatsApp',
    this.heroTag = 'whatsapp_support_fab',
  });

  /// Mensaje inicial opcional que se precargará en el chat de WhatsApp.
  final String? customMessage;

  /// Si es true, muestra una etiqueta con texto además del icono.
  final bool extended;

  /// Texto descriptivo para accesibilidad y hover.
  final String tooltip;

  /// HeroTag único para evitar colisiones en la navegación de Flutter.
  final Object? heroTag;

  static const Color whatsappGreen = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    if (extended) {
      return FloatingActionButton.extended(
        heroTag: heroTag,
        tooltip: tooltip,
        backgroundColor: whatsappGreen,
        elevation: 4,
        highlightElevation: 6,
        onPressed: () => ExternalLinkService.openWhatsAppSupport(customMessage: customMessage),
        icon: SvgPicture.asset(
          AppAssets.whatsappIcon,
          width: 22,
          height: 22,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
        label: const AppText(
          'Soporte WhatsApp',
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13.5,
        ),
      );
    }

    return FloatingActionButton(
      heroTag: heroTag,
      tooltip: tooltip,
      backgroundColor: whatsappGreen,
      elevation: 4,
      highlightElevation: 6,
      shape: const CircleBorder(),
      onPressed: () => ExternalLinkService.openWhatsAppSupport(customMessage: customMessage),
      child: SvgPicture.asset(
        AppAssets.whatsappIcon,
        width: 26,
        height: 26,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }
}

