import 'package:admivida/common/constants/app_assets.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/widgets/app_button.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_image.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

enum AppStatusType { maintenance, updateRequired }

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppStatusScreen(type: AppStatusType.maintenance);
  }
}

class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppStatusScreen(type: AppStatusType.updateRequired);
  }
}

class AppStatusScreen extends StatelessWidget {
  final AppStatusType type;

  const AppStatusScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isMaintenance = type == AppStatusType.maintenance;

    return AppScaffold(
      showAppBar: false,
      title: isMaintenance ? AppTexts.maintenance : AppTexts.updateRequired,
      mobile: _StatusView(type: type),
      tablet: _StatusView(type: type),
      desktop: _StatusView(type: type),
      marginDesktop: 0,
      marginTablet: 0,
    );
  }
}

class _StatusView extends StatelessWidget {
  final AppStatusType type;

  const _StatusView({required this.type});

  @override
  Widget build(BuildContext context) {
    final isMaintenance = type == AppStatusType.maintenance;

    final title = isMaintenance ? 'En mantenimiento' : 'Actualización requerida';
    final subtitle = isMaintenance
        ? 'Estamos realizando mejoras en la aplicación. Vuelve a intentarlo en unos minutos.'
        : 'Hay una nueva versión disponible. Actualiza la aplicación para seguir usando todas las funciones.';
    final detail = isMaintenance
        ? 'Mientras tanto, puedes revisar tu conexión o intentar nuevamente más tarde.'
        : 'Tu versión actual ya no es compatible con la última versión del servicio.';
    final accentColor = isMaintenance ? AppColors.kWarning : AppColors.kPrimaryColor;
    final animationUrl = isMaintenance
        ? 'https://assets2.lottiefiles.com/packages/lf20_9b8kwb5j.json'
        : 'https://assets2.lottiefiles.com/packages/lf20_jf2i8v9i.json';

    return Container(
      color: AppColors.kBackgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 360 || constraints.maxHeight < 700;

          final cardPadding = isCompact ? const EdgeInsets.all(20) : const EdgeInsets.all(28);
          final logoSize = isCompact ? 96.0 : 120.0;
          final animationSize = isCompact ? 180.0 : 220.0;
          final titleFontSize = isCompact ? 24.0 : 30.0;
          final subtitleFontSize = isCompact ? 14.0 : 16.0;
          final detailFontSize = isCompact ? 13.0 : 14.0;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: AppCard(
                  padding: cardPadding,
                  borderRadius: 28,
                  backgroundColor: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppImage(AdaptedFile.asset(AppAssets.logo), height: logoSize, width: logoSize, fit: BoxFit.contain),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(24)),
                        child: SizedBox(
                          width: animationSize,
                          height: animationSize,
                          child: Lottie.network(
                            animationUrl,
                            animate: true,
                            repeat: true,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(isMaintenance ? Icons.settings_outlined : Icons.system_update_alt_rounded, size: 120, color: accentColor);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppText(title, fontSize: titleFontSize, fontWeight: FontWeight.w800, color: AppColors.kPrimary900, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      AppText(subtitle, fontSize: subtitleFontSize, color: AppColors.kNeutral700, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.kNeutral100,
                          border: Border.all(color: AppColors.kNeutral200),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: AppText(detail, fontSize: detailFontSize, color: AppColors.kNeutral600, textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 28),
                      AppButton(
                        text: isMaintenance ? AppTexts.retry : AppTexts.close,
                        onPressed: () {
                          if (isMaintenance) {
                            Navigator.of(context).pushReplacementNamed('/splash');
                            return;
                          }
                          SystemNavigator.pop();
                        },
                        width: 220,
                        height: 52,
                        backgroundColor: accentColor,
                        textColor: AppColors.kWhiteColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
