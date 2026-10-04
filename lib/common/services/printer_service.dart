import 'dart:convert';
import 'dart:io';

// import 'dart:convert';
// import 'package:admivida/common/logging/app_logger.dart';
import 'package:admivida/common/models/object_to_print.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/printer_selection_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PrinterTransport { usb, bluetooth }

class PrinterChoice {
  final PrinterDevice device;
  final PrinterTransport transport;
  final String? details;

  const PrinterChoice({required this.device, required this.transport, this.details});
}

class PrinterService {
  final PrinterManager printerManager = PrinterManager.instance;
  static const MethodChannel _windowsUsbPrinterChannel = MethodChannel('admivida/windows_usb_printer');
  static const String _savedPrinterKey = 'saved_printer';
  static const String _legacySavedPrinterKey = 'saved_usb_printer';

  // 1. Escanea las impresoras USB conectadas
  Future<PermissionStatus> requestBluetoothDiscoveryPermission() async {
    if (!Platform.isAndroid) return PermissionStatus.granted;
    return Permission.locationWhenInUse.request();
  }

  Future<List<PrinterChoice>> scanPrinters({required bool includeBluetooth}) async {
    if (Platform.isWindows) {
      final printerList = await _windowsUsbPrinterChannel.invokeListMethod<Object?>('listPrinters') ?? const [];
      return printerList.map((entry) {
        if (entry is! Map<Object?, Object?> || entry['name'] is! String) {
          throw const FormatException('Windows devolvió datos de impresora no válidos.');
        }
        final model = entry['model'] as String?;
        final port = entry['port'] as String?;
        final details = [
          model,
          port,
          if (entry['available'] == false) 'Windows reporta fuera de línea',
        ].whereType<String>().where((value) => value.isNotEmpty).join(' · ');
        return PrinterChoice(
          device: PrinterDevice(name: entry['name'] as String),
          transport: PrinterTransport.usb,
          details: details.isEmpty ? null : details,
        );
      }).toList();
    }

    final devices = <PrinterChoice>[];

    Future<void> collect(Stream<PrinterDevice> stream, PrinterTransport transport) async {
      await for (final device in stream) {
        final identity = transport == PrinterTransport.bluetooth
            ? device.address ?? device.name
            : device.vendorId == null && device.productId == null
            ? device.name
            : '${device.vendorId}:${device.productId}';
        final alreadyAdded = devices.any((entry) {
          if (entry.transport != transport) return false;
          final existingIdentity = transport == PrinterTransport.bluetooth
              ? entry.device.address ?? entry.device.name
              : entry.device.vendorId == null && entry.device.productId == null
              ? entry.device.name
              : '${entry.device.vendorId}:${entry.device.productId}';
          return existingIdentity == identity;
        });
        if (!alreadyAdded) {
          devices.add(PrinterChoice(device: device, transport: transport));
        }
      }
    }

    await Future.wait([
      collect(printerManager.discovery(type: PrinterType.usb), PrinterTransport.usb),
      if (includeBluetooth) collect(printerManager.discovery(type: PrinterType.bluetooth, isBle: false), PrinterTransport.bluetooth),
    ]);
    return devices;
  }

  Future<void> savePrinter(PrinterChoice printer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _savedPrinterKey,
      jsonEncode({
        'transport': printer.transport.name,
        'name': printer.device.name,
        'address': printer.device.address,
        'vendorId': printer.device.vendorId,
        'productId': printer.device.productId,
        'details': printer.details,
      }),
    );
  }

  Future<PrinterChoice?> getSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final printerData = prefs.getString(_savedPrinterKey) ?? prefs.getString(_legacySavedPrinterKey);

    if (printerData == null) return null;

    try {
      final data = jsonDecode(printerData);
      if (data is Map<String, dynamic>) {
        final transport = PrinterTransport.values.byName(data['transport'] as String);
        final device = PrinterDevice(
          name: data['name'] as String,
          address: data['address'] as String?,
          vendorId: data['vendorId'] as String?,
          productId: data['productId'] as String?,
        );
        return PrinterChoice(device: device, transport: transport, details: data['details'] as String?);
      }
    } on FormatException {
      // Migrate printers saved by older versions, which stored USB details as CSV.
    } on TypeError {
      // Invalid persisted data is not usable as a printer configuration.
    } on ArgumentError {
      // Unknown transports can occur after a future or manually edited preference.
    }

    // Retain compatibility with USB printers saved by the previous app version.
    if (!printerData.startsWith('{')) {
      final parts = printerData.split(',');
      if (parts.length == 3) {
        return PrinterChoice(
          device: PrinterDevice(name: parts[0], vendorId: parts[1], productId: parts[2]),
          transport: PrinterTransport.usb,
        );
      }
    }
    return null;
  }

  Future<bool> printDocument(PrinterChoice printer, ObjectToPrint document) async {
    final transport = printer.transport == PrinterTransport.bluetooth ? PrinterType.bluetooth : PrinterType.usb;
    final bluetoothAddress = printer.device.address;
    if (printer.transport == PrinterTransport.bluetooth && (bluetoothAddress == null || bluetoothAddress.trim().isEmpty)) {
      debugPrint('No se puede imprimir: la impresora Bluetooth guardada no tiene dirección.');
      return false;
    }
    final windowsUsb = Platform.isWindows && printer.transport == PrinterTransport.usb;
    var connected = false;
    try {
      if (!windowsUsb) {
        final isConnected = await printerManager.connect(
          type: transport,
          model: switch (printer.transport) {
            PrinterTransport.bluetooth => BluetoothPrinterInput(address: bluetoothAddress!, name: printer.device.name, isBle: false),
            PrinterTransport.usb => UsbPrinterInput(name: printer.device.name, productId: printer.device.productId, vendorId: printer.device.vendorId),
          },
        );

        if (!isConnected) return false;
        connected = true;
      }

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
      final sent = windowsUsb
          ? await _windowsUsbPrinterChannel.invokeMethod<bool>('printRaw', {'name': printer.device.name, 'bytes': Uint8List.fromList(bytes)}) ?? false
          : await printerManager.send(type: transport, bytes: bytes);
      if (sent) await Future.delayed(const Duration(milliseconds: 500));
      return sent;
    } catch (e) {
      debugPrint('Error de impresión: $e');
      return false;
    } finally {
      if (connected) {
        try {
          await printerManager.disconnect(type: transport);
        } catch (e) {
          debugPrint('Error al desconectar la impresora: $e');
        }
      }
    }
  }

  Future<void> showPrintersAndPrint(BuildContext context, ObjectToPrint document) async {
    final savedPrinter = await getSavedPrinter();

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
    await prefs.remove(_legacySavedPrinterKey);
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
