import 'package:flutter/material.dart';

/// Representa una novedad individual (funcionalidad, mejora o corrección).
class WhatsNewItem {
  final String title;
  final String description;
  final String? iconName;

  const WhatsNewItem({
    required this.title,
    required this.description,
    this.iconName,
  });

  factory WhatsNewItem.fromJson(dynamic json) {
    if (json is String) {
      final parts = json.split(':');
      if (parts.length > 1) {
        return WhatsNewItem(
          title: parts.first.trim(),
          description: parts.sublist(1).join(':').trim(),
        );
      }
      return WhatsNewItem(title: json.trim(), description: '');
    }
    if (json is Map) {
      return WhatsNewItem(
        title: (json['title'] ?? json['name'] ?? '').toString().trim(),
        description: (json['description'] ?? json['desc'] ?? json['detail'] ?? '').toString().trim(),
        iconName: json['icon']?.toString().toLowerCase().trim(),
      );
    }
    return WhatsNewItem(title: json.toString(), description: '');
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        if (iconName != null) 'icon': iconName,
      };

  /// Mapea el icono según la palabra clave o el nombre del icono
  IconData get iconData {
    final key = '${iconName ?? ''} $title'.toLowerCase();
    if (key.contains('barcode') || key.contains('escan') || key.contains('código') || key.contains('codigo')) {
      return Icons.qr_code_scanner_rounded;
    }
    if (key.contains('update') || key.contains('actualiz') || key.contains('descarg') || key.contains('download')) {
      return Icons.system_update_alt_rounded;
    }
    if (key.contains('speed') ||
        key.contains('velocidad') ||
        key.contains('rendimiento') ||
        key.contains('rapidez') ||
        key.contains('rocket') ||
        key.contains('optimiz')) {
      return Icons.bolt_rounded;
    }
    if (key.contains('vendedor') || key.contains('usuario') || key.contains('user') || key.contains('perfil')) {
      return Icons.person_pin_rounded;
    }
    if (key.contains('pos') || key.contains('venta') || key.contains('carrito') || key.contains('cart')) {
      return Icons.point_of_sale_rounded;
    }
    if (key.contains('print') || key.contains('impres')) {
      return Icons.print_rounded;
    }
    if (key.contains('design') || key.contains('diseño') || key.contains('color') || key.contains('interfaz')) {
      return Icons.palette_outlined;
    }
    if (key.contains('fix') || key.contains('correc') || key.contains('bug') || key.contains('error')) {
      return Icons.build_circle_outlined;
    }
    if (key.contains('ticket') || key.contains('descuento') || key.contains('desc') || key.contains('recibo')) {
      return Icons.receipt_long_rounded;
    }
    if (key.contains('delete') || key.contains('eliminar') || key.contains('borrar') || key.contains('trash')) {
      return Icons.delete_outline_rounded;
    }
    if (key.contains('bell') || key.contains('campan') || key.contains('notif') || key.contains('novedad')) {
      return Icons.notifications_active_outlined;
    }
    if (key.contains('security') ||
        key.contains('seguridad') ||
        key.contains('candado') ||
        key.contains('shield') ||
        key.contains('bóveda') ||
        key.contains('boveda') ||
        key.contains('caja')) {
      return Icons.shield_rounded;
    }
    if (key.contains('wallet') ||
        key.contains('personal') ||
        key.contains('cartera') ||
        key.contains('finanzas')) {
      return Icons.account_balance_wallet_rounded;
    }
    if (key.contains('device') ||
        key.contains('dispositivo') ||
        key.contains('sesion') ||
        key.contains('sesión')) {
      return Icons.devices_rounded;
    }
    if (key.contains('analytics') ||
        key.contains('reporte') ||
        key.contains('report') ||
        key.contains('grafica') ||
        key.contains('gráfica') ||
        key.contains('métrica') ||
        key.contains('metrica') ||
        key.contains('kpi') ||
        key.contains('rentab')) {
      return Icons.analytics_rounded;
    }
    return Icons.auto_awesome_rounded;
  }
}

/// Historial de versiones anteriores
class WhatsNewHistoryItem {
  final String versionName;
  final int? versionCode;
  final String? releaseNotes;
  final List<WhatsNewItem> items;
  final String? publishedAt;

  const WhatsNewHistoryItem({
    required this.versionName,
    this.versionCode,
    this.releaseNotes,
    this.items = const [],
    this.publishedAt,
  });

  factory WhatsNewHistoryItem.fromJson(Map<String, dynamic> json) {
    List<WhatsNewItem> parsedItems = [];
    if (json['whatsNew'] is List) {
      parsedItems = (json['whatsNew'] as List).map((e) => WhatsNewItem.fromJson(e)).toList();
    } else if (json['releaseNotes'] != null) {
      parsedItems = _parseNotesToItems(json['releaseNotes'].toString());
    }

    return WhatsNewHistoryItem(
      versionName: json['versionName']?.toString() ?? '',
      versionCode: (json['versionCode'] as num?)?.toInt(),
      releaseNotes: json['releaseNotes']?.toString(),
      items: parsedItems,
      publishedAt: json['publishedAt']?.toString(),
    );
  }

  static List<WhatsNewItem> _parseNotesToItems(String text) {
    final lines = text.split('\n');
    final items = <WhatsNewItem>[];
    for (final rawLine in lines) {
      final line = rawLine.trim().replaceFirst(RegExp(r'^[•\-\*]\s*'), '').trim();
      if (line.isNotEmpty) {
        items.add(WhatsNewItem.fromJson(line));
      }
    }
    return items;
  }

  Map<String, dynamic> toJson() => {
        'versionName': versionName,
        if (versionCode != null) 'versionCode': versionCode,
        if (releaseNotes != null) 'releaseNotes': releaseNotes,
        if (items.isNotEmpty) 'whatsNew': items.map((x) => x.toJson()).toList(),
        if (publishedAt != null) 'publishedAt': publishedAt,
      };
}

/// Modelo completo de novedades de la versión
class WhatsNewModel {
  final int versionCode;
  final String versionName;
  final String? releaseNotes;
  final List<WhatsNewItem> items;
  final List<WhatsNewHistoryItem> history;

  const WhatsNewModel({
    required this.versionCode,
    required this.versionName,
    this.releaseNotes,
    this.items = const [],
    this.history = const [],
  });

  factory WhatsNewModel.fromJson(Map<String, dynamic> json) {
    List<WhatsNewItem> parsedItems = [];

    if (json['whatsNew'] is List) {
      parsedItems = (json['whatsNew'] as List)
          .map((e) => WhatsNewItem.fromJson(e))
          .where((item) => item.title.isNotEmpty)
          .toList();
    }

    final rawNotes = json['releaseNotes']?.toString().trim();
    if (parsedItems.isEmpty && rawNotes != null && rawNotes.isNotEmpty) {
      parsedItems = WhatsNewHistoryItem._parseNotesToItems(rawNotes);
    }

    List<WhatsNewHistoryItem> parsedHistory = [];
    if (json['history'] is List) {
      parsedHistory = (json['history'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => WhatsNewHistoryItem.fromJson(e))
          .toList();
    }

    return WhatsNewModel(
      versionCode: (json['versionCode'] as num?)?.toInt() ?? 0,
      versionName: json['versionName']?.toString() ?? '',
      releaseNotes: rawNotes,
      items: parsedItems,
      history: parsedHistory,
    );
  }

  Map<String, dynamic> toJson() => {
        'versionCode': versionCode,
        'versionName': versionName,
        if (releaseNotes != null) 'releaseNotes': releaseNotes,
        'whatsNew': items.map((x) => x.toJson()).toList(),
        if (history.isNotEmpty) 'history': history.map((x) => x.toJson()).toList(),
      };

  /// Novedades empaquetadas por defecto para la versión actual en caso de no haber conexión
  static WhatsNewModel fallback() => const WhatsNewModel(
        versionCode: 6,
        versionName: '0.8.0 (Beta)',
        releaseNotes:
            'Pagos mixtos y ventas en espera en el POS, comprobantes PDF tamaño Carta listos para compartir por WhatsApp, fiados y abonos, cortes de caja X/Z con modo ciego, modo sin conexión, Kardex de inventario e interfaz renovada.',
        items: [
          WhatsNewItem(
            title: 'Punto de Venta Ágil y Pagos Mixtos',
            description:
                'Cobra combinando múltiples métodos de pago y cuentas en una misma venta, guarda carritos en espera, asigna precios especiales y selecciona clientes rápidamente.',
            iconName: 'pos',
          ),
          WhatsNewItem(
            title: 'Comprobantes PDF Carta y WhatsApp',
            description:
                'Genera notas de venta, recibos de abono y cortes de caja en PDF tamaño Carta para compartir directamente por WhatsApp o imprimir en hoja normal.',
            iconName: 'ticket',
          ),
          WhatsNewItem(
            title: 'Control de Fiados, Créditos y Abonos',
            description:
                'Configura límites de crédito por cliente, consulta adeudos pendientes, registra abonos parciales con cálculo exacto y emite comprobantes al instante.',
            iconName: 'wallet',
          ),
          WhatsNewItem(
            title: 'Cortes de Caja X/Z, Modo Ciego y Offline',
            description:
                'Opera turnos por caja con cortes X/Z y modo ciego, además de registrar ventas sin internet en una cola local segura con sincronización automática.',
            iconName: 'shield',
          ),
          WhatsNewItem(
            title: 'Kardex de Inventario y Reportes Avanzados',
            description:
                'Consulta cada movimiento y ajuste de stock en el detalle del producto, revisa rentabilidad neta real, valorización de inventario y finanzas personales.',
            iconName: 'analytics',
          ),
          WhatsNewItem(
            title: 'Catálogo Visual, Escáner y Diseño Renovado',
            description:
                'Navegación mejorada en escritorio y móvil, filtros por rango de fechas, vista visual de variantes y lectura rápida de códigos de barras o SKU.',
            iconName: 'barcode',
          ),
        ],
      );
}

