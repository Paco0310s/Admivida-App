import 'dart:io';

import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerSheet extends StatefulWidget {
  final void Function(String code) onCode;
  const BarcodeScannerSheet({super.key, required this.onCode});

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet> {
  bool _handled = false;
  final MobileScannerController _controller = MobileScannerController(formats: [BarcodeFormat.code39, BarcodeFormat.code128, BarcodeFormat.ean13]);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _scannerErrorMessage(MobileScannerException error) {
    return switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied => 'El navegador denegó el acceso a la cámara. Permite el acceso en los ajustes del sitio y vuelve a intentarlo.',
      MobileScannerErrorCode.unsupported => 'No se encontró una cámara compatible en este dispositivo.',
      _ => 'No se pudo iniciar la cámara. Verifica los permisos y abre la aplicación mediante HTTPS o localhost.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Builder(
        builder: (_) {
          if (Platform.isWindows) {
            return const SizedBox(
              height: 200,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: AppText(
                    'Escaneo de código de barras no disponible en Windows. Por favor, utiliza un dispositivo móvil.',
                    textAlign: TextAlign.center,
                    color: Colors.red,
                  ),
                ),
              ),
            );
          }
          return SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(3)),
                ),
                const SizedBox(height: 12),
                const AppText('Escanea código de barras', fontWeight: FontWeight.w600),
                const SizedBox(height: 12),
                SizedBox(
                  height: 280,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: MobileScanner(
                      controller: _controller,
                      onDetect: (capture) {
                        if (_handled) return;
                        final barcodes = capture.barcodes;
                        if (barcodes.isEmpty) return;
                        final code = barcodes.first.rawValue;
                        if (code == null) return;
                        _handled = true;
                        widget.onCode(code.trim());
                        NavigationService.maybePop(context);
                      },
                      errorBuilder: (context, error) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: AppText(
                              _scannerErrorMessage(error),
                              textAlign: TextAlign.center,
                              color: Colors.red,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () async {
                    try {
                      await _controller.toggleTorch();
                      if (!mounted) return;
                      setState(() {});
                    } catch (_) {
                      if (!mounted) return;
                      SnackbarUtil.showWarning(null, 'Flash no disponible en este dispositivo');
                    }
                  },
                  icon: const Icon(Icons.flashlight_on_outlined),
                  label: const AppText('Flash'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}
