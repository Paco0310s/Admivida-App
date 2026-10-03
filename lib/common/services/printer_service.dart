// import 'dart:convert';
// import 'package:admivida/common/logging/app_logger.dart';
import 'package:admivida/common/models/object_to_print.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/printer_selection_modal.dart';
import 'package:flutter/material.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterService {
  final PrinterManager printerManager = PrinterManager.instance;
  static const String _savedPrinterKey = 'saved_usb_printer';

  // 1. Escanea las impresoras USB conectadas
  Future<List<PrinterDevice>> scanPrinters() async {
    List<PrinterDevice> devices = [];

    // 1. Escanear impresoras USB
    PrinterManager.instance.discovery(type: PrinterType.usb).listen((device) {
      if (!devices.any((d) => d.address == device.address)) devices.add(device);
    });

    // 2. Escanear impresoras Bluetooth
    PrinterManager.instance.discovery(type: PrinterType.bluetooth).listen((device) {
      if (!devices.any((d) => d.address == device.address)) devices.add(device);
    });

    // Le damos un par de segundos al escáner para recolectar las respuestas
    await Future.delayed(const Duration(seconds: 2));
    return devices;
  }

  // 2. Guarda la impresora elegida en memoria
  Future<void> savePrinter(PrinterDevice printer) async {
    final prefs = await SharedPreferences.getInstance();
    // Guardamos el nombre y el vendor/product ID separados por comas
    final printerData = '${printer.name},${printer.vendorId},${printer.productId}';
    await prefs.setString(_savedPrinterKey, printerData);
  }

  // 3. Obtiene la impresora guardada
  Future<PrinterDevice?> getSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final printerData = prefs.getString(_savedPrinterKey);

    if (printerData != null) {
      final parts = printerData.split(',');
      if (parts.length == 3) {
        return PrinterDevice(name: parts[0], vendorId: parts[1], productId: parts[2]);
      }
    }
    return null;
  }

  // 4. Proceso de Impresión del Objeto
  Future<bool> printDocument(PrinterDevice printer, ObjectToPrint document) async {
    try {
      bool isConnected = await printerManager.connect(
        type: PrinterType.usb,
        model: UsbPrinterInput(name: printer.name, productId: printer.productId, vendorId: printer.vendorId),
      );

      if (!isConnected) return false;

      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);
      List<int> bytes = [];

      // Cabecera
      bytes += generator.text(
        document.businessName,
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
      );
      bytes += generator.text('Folio: ${document.ticketId}', styles: const PosStyles(align: PosAlign.center));
      // Formatear la fecha a un string legible
      bytes += generator.text('Fecha: ${document.date.toString()}', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('Le atendió: ${document.cashierName}', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('Cliente: ${document.customerName}', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.hr();

      // Cuerpo (Productos)
      for (final row in document.rows) {
        // Puedes dividir la fila en columnas para alinear cantidades y precios
        bytes += generator.row([
          PosColumn(text: '${row.quantity}x', width: 2),
          PosColumn(text: row.description, width: 7),
          PosColumn(
            text: '\$${row.total.toStringAsFixed(2)}',
            width: 3,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }
      bytes += generator.hr();

      // Totales
      bytes += generator.row([
        PosColumn(text: 'Subtotal:', width: 6),
        PosColumn(
          text: '\$${document.subtotal.toStringAsFixed(2)}',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      if (document.discount > 0) {
        bytes += generator.row([
          PosColumn(text: 'Descuento:', width: 6),
          PosColumn(
            text: '-\$${document.discount.toStringAsFixed(2)}',
            width: 6,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }

      bytes += generator.row([
        PosColumn(
          text: 'TOTAL:',
          width: 6,
          styles: const PosStyles(bold: true, height: PosTextSize.size2),
        ),
        PosColumn(
          text: '\$${document.total.toStringAsFixed(2)}',
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2),
        ),
      ]);

      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'Su pago:', width: 6),
        PosColumn(
          text: '\$${document.amountPaid.toStringAsFixed(2)}',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Su cambio:', width: 6),
        PosColumn(
          text: '\$${document.changeGiven.toStringAsFixed(2)}',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      bytes += generator.feed(2);
      bytes += generator.text('¡Gracias por su compra!', styles: const PosStyles(align: PosAlign.center));

      // --- Footer de Admivida ---
      bytes += generator.feed(1);
      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text(
        'Ticket generado por Admivida POS',
        styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB),
      );

      // Opcional: Si tienes una página web o contacto
      // bytes += generator.text('www.tu-pagina.com', styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB));

      bytes += generator.feed(2);

      // Cajón y corte
      if (document.openDrawer) {
        bytes += generator.drawer(pin: PosDrawer.pin2);
        bytes += generator.drawer(pin: PosDrawer.pin5);
      }
      bytes += generator.cut();

      // Decodifica los bytes saltando los caracteres ocultos del hardware
      // final String ticketPreview = latin1.decode(bytes, allowInvalid: true);

      // AppLogger.info('BASE64: ${base64Encode(bytes)}');

      // Imprímelo en tu consola usando tu AppLogger
      // AppLogger.info('\n========== TICKET PREVIEW ==========\n$ticketPreview\n====================================');

      // Enviar e imprimir
      printerManager.send(type: PrinterType.usb, bytes: bytes);
      await Future.delayed(const Duration(milliseconds: 500)); // Pequeña pausa para asegurar el envío
      await printerManager.disconnect(type: PrinterType.usb);

      return true;
    } catch (e) {
      debugPrint('Error de impresión: $e');
      return false;
    }
  }

  Future<void> showPrintersAndPrint(BuildContext context, ObjectToPrint document) async {
    PrinterDevice? savedPrinter = await getSavedPrinter();

    if (savedPrinter != null) {
      bool success = await printDocument(savedPrinter, document);
      if (success) return;

      if (context.mounted) {
        SnackbarUtil.showError(context, 'Impresora guardada no disponible. Buscando dispositivos...');
      }
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext modalContext) {
        return PrinterSelectionModal(printerService: this, document: document);
      },
    );
  }

  // Elimina la impresora de la memoria
  Future<void> clearSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedPrinterKey);
  }

  // NUEVA FUNCIÓN EN PrinterService: Solo abre el modal para vincular
  Future<void> showPrinterSelectionModal(BuildContext context) async {
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isDismissible: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext modalContext) {
        return PrinterSelectionModal(printerService: this, document: null);
      },
    );
  }
}

final printerServiceProvider = Provider<PrinterService>((ref) {
  return PrinterService();
});

final hasSavedPrinterProvider = FutureProvider.autoDispose<bool>((ref) async {
  final printer = await ref.read(printerServiceProvider).getSavedPrinter();
  return printer != null;
});
