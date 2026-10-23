import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/services/whats_new_service.dart';
import 'package:flutter/material.dart';

/// Botón con forma de campana para el AppBar que permite al usuario
/// consultar las novedades de la versión actual y muestra un punto indicador
/// cuando hay una nueva versión sin leer.
class WhatsNewBellButton extends StatelessWidget {
  final Color? color;

  const WhatsNewBellButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: WhatsNewService.hasUnreadNotes,
      builder: (context, hasUnread, _) {
        final iconColor = color ?? AppColors.kPrimaryColor;

        return IconButton(
          tooltip: 'Novedades de la versión',
          onPressed: () => WhatsNewService.showManually(context),
          icon: Badge(
            isLabelVisible: hasUnread,
            backgroundColor: AppColors.kError,
            smallSize: 8,
            child: Icon(
              hasUnread ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
              color: iconColor,
            ),
          ),
        );
      },
    );
  }
}

