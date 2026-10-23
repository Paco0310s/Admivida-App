import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/models/whats_new_model.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/widgets/app_button.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// Modal dialog responsivo y estilizado que presenta las novedades de cada versión
class WhatsNewDialog extends StatelessWidget {
  final WhatsNewModel whatsNew;

  const WhatsNewDialog({super.key, required this.whatsNew});

  /// Muestra el diálogo en pantalla
  static Future<void> show(BuildContext context, {required WhatsNewModel whatsNew}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => WhatsNewDialog(whatsNew: whatsNew),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 500;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 32,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado decorativo
            _buildHeader(context),

            // Contenido desplazable con las novedades
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mensaje introductorio
                    const AppText(
                      'Preparamos estas mejoras y nuevas funciones para brindarte la mejor experiencia en tu negocio:',
                      fontSize: 13,
                      color: AppColors.kNeutral600,
                    ),
                    const Gap(16),

                    // Tarjetas de novedades
                    ...whatsNew.items.map((item) => _buildItemCard(item)),

                    // Historial de versiones anteriores (si existe en el JSON)
                    if (whatsNew.history.isNotEmpty) ...[
                      const Gap(12),
                      _buildHistorySection(),
                    ],
                  ],
                ),
              ),
            ),

            // Pie con recordatorio y botón de acción
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.kNeutral50,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          bottom: BorderSide(color: AppColors.kNeutral200, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.kPrimaryColor, AppColors.kPrimary600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.kPrimaryColor.withAlpha(50),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.kPrimary50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.kPrimaryColor.withAlpha(60)),
                  ),
                  child: AppText(
                    'Versión ${whatsNew.versionName}',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.kPrimaryColor,
                  ),
                ),
                const Gap(6),
                const AppText(
                  '¡Novedades de la versión!',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.kNeutral900,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => NavigationService.pop(context),
            icon: const Icon(Icons.close_rounded, color: AppColors.kNeutral500),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(WhatsNewItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.kNeutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.kPrimary50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.iconData,
              color: AppColors.kPrimaryColor,
              size: 22,
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  item.title,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.kNeutral900,
                ),
                if (item.description.isNotEmpty) ...[
                  const Gap(4),
                  AppText(
                    item.description,
                    fontSize: 12.5,
                    color: AppColors.kNeutral600,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kNeutral50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.kNeutral200),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: const Icon(Icons.history_rounded, color: AppColors.kNeutral600),
          title: const AppText(
            'Versiones anteriores',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.kNeutral800,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: whatsNew.history.map((h) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.kNeutral200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'Versión ${h.versionName}',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kPrimaryColor,
                        ),
                        if (h.releaseNotes != null && h.releaseNotes!.isNotEmpty) ...[
                          const Gap(4),
                          AppText(
                            h.releaseNotes!,
                            fontSize: 12,
                            color: AppColors.kNeutral700,
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.kNeutral200, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.notifications_active_outlined, size: 16, color: AppColors.kNeutral500),
              Gap(8),
              Expanded(
                child: AppText(
                  'Podrás volver a consultar estas novedades tocando la campanita en el inicio.',
                  fontSize: 11.5,
                  color: AppColors.kNeutral500,
                ),
              ),
            ],
          ),
          const Gap(14),
          AppButton(
            text: '¡Entendido, gracias!',
            onPressed: () => NavigationService.pop(context),
            backgroundColor: AppColors.kPrimaryColor,
          ),
        ],
      ),
    );
  }
}

