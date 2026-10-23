import 'package:admivida/common/services/external_link_service.dart';
import 'dart:io';

import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/services/windows_updater_service.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

enum _UpdateStep { idle, downloading, installing, error }

/// Diálogo de actualización para Windows: muestra la nueva versión, descarga el instalador
/// con barra de progreso y lo ejecuta para que la app se actualice y se vuelva a abrir sola.
class WindowsUpdateDialog extends StatefulWidget {
  const WindowsUpdateDialog({super.key, required this.info});

  final WindowsUpdateInfo info;

  static bool _isShowing = false;

  /// Muestra el diálogo (evita abrir dos a la vez).
  static Future<void> show(BuildContext context, WindowsUpdateInfo info) async {
    if (_isShowing) return;
    _isShowing = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PopScope(canPop: !info.mandatory, child: WindowsUpdateDialog(info: info)),
      );
    } finally {
      _isShowing = false;
    }
  }

  @override
  State<WindowsUpdateDialog> createState() => _WindowsUpdateDialogState();
}

class _WindowsUpdateDialogState extends State<WindowsUpdateDialog> {
  _UpdateStep _step = _UpdateStep.idle;
  double? _progress = 0;
  String? _errorMessage;
  CancelToken? _cancelToken;

  WindowsUpdateInfo get _info => widget.info;

  Future<void> _startUpdate() async {
    _cancelToken = CancelToken();
    setState(() {
      _step = _UpdateStep.downloading;
      _progress = 0;
      _errorMessage = null;
    });

    try {
      final installer = await WindowsUpdaterService.downloadInstaller(
        _info,
        cancelToken: _cancelToken,
        onProgress: (value) {
          if (mounted) setState(() => _progress = value);
        },
      );

      if (!mounted) return;
      setState(() => _step = _UpdateStep.installing);

      // Pequeña pausa para que el usuario alcance a leer el mensaje
      await Future.delayed(const Duration(milliseconds: 1200));
      await WindowsUpdaterService.launchInstallerAndExit(installer);
    } on DioException catch (e) {
      if (!mounted) return;
      if (CancelToken.isCancel(e)) {
        setState(() => _step = _UpdateStep.idle);
        return;
      }
      setState(() {
        _step = _UpdateStep.error;
        _errorMessage = 'No se pudo descargar la actualización. Revisa tu conexión a internet e intenta de nuevo.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _UpdateStep.error;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _cancelDownload() {
    _cancelToken?.cancel();
  }

  void _postpone() {
    WindowsUpdaterService.dismiss(_info);
    NavigationService.pop(context);
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _step == _UpdateStep.downloading || _step == _UpdateStep.installing;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.kPrimary50, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.system_update_alt_rounded, color: AppColors.kPrimaryColor),
          ),
          const Gap(12),
          const Expanded(child: AppText('Nueva actualización disponible', fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'La versión ${_info.versionName} de Admivida ya está disponible. Tienes la versión ${AppConfig.appVersionName}.',
              fontSize: 14,
              color: AppColors.kNeutral700,
            ),
            if (_info.mandatory) ...[
              const Gap(12),
              _buildBanner(
                icon: Icons.priority_high_rounded,
                color: AppColors.kWarning,
                text: 'Esta actualización es obligatoria para seguir usando la aplicación.',
              ),
            ],
            if (_info.releaseNotes != null && _info.releaseNotes!.isNotEmpty) ...[
              const Gap(14),
              const AppText('Novedades:', fontWeight: FontWeight.bold, fontSize: 13),
              const Gap(6),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 160),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.kNeutral50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.kNeutral200),
                ),
                child: SingleChildScrollView(
                  child: AppText(_info.releaseNotes!, fontSize: 13, color: AppColors.kNeutral700),
                ),
              ),
            ],
            if (_step == _UpdateStep.downloading) ...[
              const Gap(18),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 10,
                  backgroundColor: AppColors.kNeutral200,
                  color: AppColors.kPrimaryColor,
                ),
              ),
              const Gap(8),
              AppText(
                _progress != null ? 'Descargando... ${(_progress! * 100).toStringAsFixed(0)}%' : 'Descargando...',
                fontSize: 13,
                color: AppColors.kNeutral600,
              ),
            ],
            if (_step == _UpdateStep.installing) ...[
              const Gap(18),
              _buildBanner(
                icon: Platform.isWindows ? Icons.install_desktop_rounded : Icons.install_mobile_rounded,
                color: AppColors.kSuccess,
                text: Platform.isWindows
                    ? 'Instalando actualización... La aplicación se cerrará y se abrirá de nuevo automáticamente.'
                    : 'Abriendo instalador de Android... Confirma la instalación en pantalla para actualizar.',
              ),
            ],
            if (_step == _UpdateStep.error && _errorMessage != null) ...[
              const Gap(18),
              _buildBanner(icon: Icons.error_outline_rounded, color: Colors.red, text: _errorMessage!),
              const Gap(8),
              Center(
                child: TextButton.icon(
                  onPressed: () => ExternalLinkService.openAdmividaWeb(),
                  icon: const Icon(Icons.language_rounded, size: 15, color: AppColors.kPrimaryColor),
                  label: const Text(
                    'Descargar instalador desde admivida.pacosotelo.com',
                    style: TextStyle(color: AppColors.kPrimaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_info.mandatory && !isBusy)
          TextButton(
            onPressed: _postpone,
            child: const Text('Más tarde', style: TextStyle(color: AppColors.kNeutral600)),
          ),
        if (_step == _UpdateStep.downloading)
          TextButton(
            onPressed: _cancelDownload,
            child: const Text('Cancelar', style: TextStyle(color: AppColors.kNeutral600)),
          ),
        ElevatedButton.icon(
          onPressed: isBusy ? null : _startUpdate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.kPrimaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: isBusy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Icon(_step == _UpdateStep.error ? Icons.refresh_rounded : Icons.download_rounded, size: 18),
          label: Text(_step == _UpdateStep.error ? 'Reintentar' : 'Actualizar ahora'),
        ),
      ],
    );
  }

  Widget _buildBanner({required IconData icon, required Color color, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const Gap(8),
          Expanded(child: AppText(text, fontSize: 12.5, color: AppColors.kNeutral800)),
        ],
      ),
    );
  }
}


/// Alias para usar indistintamente en Windows o Android
typedef AppUpdateDialog = WindowsUpdateDialog;
