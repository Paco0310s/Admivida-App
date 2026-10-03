import 'package:admivida/common/models/object_to_print.dart';
import 'package:admivida/common/services/printer_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';

class PrinterSelectionModal extends StatefulWidget {
  final PrinterService printerService;
  final ObjectToPrint? document;

  const PrinterSelectionModal({super.key, required this.printerService, this.document});

  @override
  State<PrinterSelectionModal> createState() => PrinterSelectionModalState();
}

class PrinterSelectionModalState extends State<PrinterSelectionModal> {
  List<PrinterDevice> _devices = [];
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _scanForPrinters();
  }

  Future<void> _scanForPrinters() async {
    final devices = await widget.printerService.scanPrinters();

    setState(() {
      _devices = devices;
      _isScanning = false;
    });

    // Validar si no encontró ninguna para mostrar el SnackBar de advertencia
    if (devices.isEmpty && mounted) {
      Navigator.pop(context); // Cierra el modal
      SnackbarUtil.showWarning(context, '⚠ No se encontraron impresoras USB conectadas.');
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

          if (_isScanning)
            Center(child: Column(children: const [CircularProgressIndicator(), SizedBox(height: 8), Text('Escaneando impresoras...')]))
          else
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final device = _devices[index];
                  return ListTile(
                    leading: const Icon(Icons.print),
                    title: Text(device.name),
                    subtitle: const Text('Puerto USB'),
                    onTap: () async {
                      // 1. Guardar como favorita
                      await widget.printerService.savePrinter(device);

                      // 2. Cerrar el modal
                      if (context.mounted) Navigator.pop(context);

                      // 3. Imprimir SOLO si hay un documento
                      if (widget.document != null) {
                        bool success = await widget.printerService.printDocument(device, widget.document!);

                        if (!success && context.mounted) {
                          SnackbarUtil.showError(context, 'Error al imprimir. Revisa la conexión o el formato.');
                        }
                      } else {
                        // 4. Si no hay documento, es solo vinculación manual. Mostramos éxito.
                        if (context.mounted) {
                          SnackbarUtil.showSuccess(context, 'Impresora vinculada correctamente.');
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
