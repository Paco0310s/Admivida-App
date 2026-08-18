import 'dart:io';
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        width: double.infinity,
        child: Builder(
          builder: (context) {
            if (!Platform.isAndroid || !Platform.isIOS) {
              return SizedBox(
                width: double.infinity,
                height: 120,
                child: Center(
                  child: Text(
                    'Opción no disponible en este dispositivo',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(3)),
                ),
                const SizedBox(height: 12),
                const Text('Escanea código de barras', style: TextStyle(fontWeight: FontWeight.w600)),
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
                        Navigator.of(context).maybePop();
                      },
                      errorBuilder: (context, error) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Cámara no disponible en este dispositivo (${error.errorCode.name})',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
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
                    final messenger = ScaffoldMessenger.maybeOf(context);

                    try {
                      await _controller.toggleTorch();
                      if (!mounted) return;
                      setState(() {});
                    } catch (_) {
                      if (!mounted || messenger == null) return;
                      messenger.showSnackBar(const SnackBar(content: Text('Flash no disponible en este dispositivo')));
                    }
                  },
                  icon: const Icon(Icons.flashlight_on_outlined),
                  label: const Text('Flash'),
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }
}
