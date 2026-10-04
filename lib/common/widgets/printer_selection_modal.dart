import 'dart:io';

import 'package:admivida/common/models/object_to_print.dart';
import 'package:admivida/common/services/printer_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PrinterSelectionModal extends StatefulWidget {
  final PrinterService printerService;
  final ObjectToPrint? document;

  const PrinterSelectionModal({super.key, required this.printerService, this.document});

  @override
  State<PrinterSelectionModal> createState() => PrinterSelectionModalState();
}

class PrinterSelectionModalState extends State<PrinterSelectionModal> {
  List<PrinterChoice> _devices = [];
  bool _isScanning = true;
  String? _scanError;

  @override
  void initState() {
    super.initState();
    _scanForPrinters();
  }

  Future<void> _scanForPrinters() async {
    try {
      final permissionStatus = await widget.printerService.requestBluetoothDiscoveryPermission();
      if (!mounted) return;
      final bluetoothSupported = Platform.isAndroid || Platform.isIOS;
      final includeBluetooth = bluetoothSupported && permissionStatus == PermissionStatus.granted;
      final devices = await widget.printerService.scanPrinters(includeBluetooth: includeBluetooth);

      if (!mounted) return;
      setState(() {
        _devices = devices;
        _isScanning = false;
      });

      if (devices.isEmpty) {
        final message = includeBluetooth
            ? 'No se encontraron impresoras USB o Bluetooth emparejadas.'
            : Platform.isWindows
                ? 'Windows no reportó impresoras instaladas. Conecta la impresora e instala su controlador.'
                : 'No se encontraron impresoras USB conectadas.';
        SnackbarUtil.showWarning(context, message);
      } else if (bluetoothSupported && !includeBluetooth) {
        final message = permissionStatus == PermissionStatus.permanentlyDenied
            ? 'Permite la ubicación en los ajustes para buscar impresoras Bluetooth. La búsqueda USB sigue disponible.'
            : 'Permite la ubicación para buscar impresoras Bluetooth. La búsqueda USB sigue disponible.';
        SnackbarUtil.showWarning(context, message);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _scanError = 'No se pudieron buscar impresoras: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Selecciona una impresora', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            Platform.isWindows
                ? 'Se muestran impresoras instaladas en un puerto USB. Instala el controlador térmico compatible con ESC/POS. Bluetooth no está disponible en esta versión.'
                : 'Para usar Bluetooth, emparéjalo primero desde los ajustes de Android. También puedes conectar una impresora por USB OTG.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          if (_isScanning)
            Center(child: Column(children: const [CircularProgressIndicator(), SizedBox(height: 8), Text('Escaneando impresoras...')]))
          else if (_scanError != null)
            Padding(padding: const EdgeInsets.all(16), child: Text(_scanError!, style: const TextStyle(color: Colors.red)))
          else if (_devices.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('No se encontraron impresoras.'))
          else
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final printer = _devices[index];
                  return ListTile(
                    leading: const Icon(Icons.print),
                    title: Text(printer.device.name),
                    subtitle: Text([
                      if (printer.transport == PrinterTransport.bluetooth) 'Bluetooth' else 'USB',
                      if (printer.details != null) printer.details!,
                    ].join(' · ')),
                    onTap: () async {
                      // 1. Guardar como favorita
                      await widget.printerService.savePrinter(printer);

                      // 2. Cerrar el modal
                      if (context.mounted) Navigator.pop(context);

                      // 3. Imprimir SOLO si hay un documento
                      if (widget.document != null) {
                        final success = await widget.printerService.printDocument(printer, widget.document!);

                        if (!success && context.mounted) {
                          final message = Platform.isWindows
                              ? 'No se pudo imprimir. Verifica que la impresora esté conectada por USB y que su controlador acepte ESC/POS RAW.'
                              : 'No se pudo imprimir. Verifica la conexión y el tipo de impresora.';
                          SnackbarUtil.showError(context, message);
                        }
                      } else {
                        // 4. Si no hay documento, es solo vinculación manual. Mostramos éxito.
                        if (context.mounted) {
                          SnackbarUtil.showSuccess(context, 'Impresora seleccionada correctamente.');
                        }
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
