import 'dart:convert';

import 'package:admivida/business/features/add_sale/models/create_sale_detail_inner_dto.dart';
import 'package:admivida/common/logging/app_logger.dart';
import 'package:admivida/common/services/isar_cache_service.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class HeldCartTicket {
  final String id;
  final String businessId;
  final String label;
  final String? clientUserId;
  final String clientName;
  final double discountAmount;
  final String? notes;
  final DateTime createdAt;
  final List<CreateSaleDetailInnerDto> items;

  const HeldCartTicket({
    required this.id,
    required this.businessId,
    required this.label,
    this.clientUserId,
    required this.clientName,
    required this.discountAmount,
    this.notes,
    required this.createdAt,
    required this.items,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get total => (subtotal - discountAmount).clamp(0.0, double.infinity);
  double get totalItems => items.fold(0.0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'label': label,
      'clientUserId': clientUserId,
      'clientName': clientName,
      'discountAmount': discountAmount,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'items': items.map((e) => e.toLocalJson()).toList(),
    };
  }

  factory HeldCartTicket.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return HeldCartTicket(
      id: json['id'] as String? ?? const Uuid().v4(),
      businessId: json['businessId'] as String? ?? '',
      label: json['label'] as String? ?? 'Ticket en espera',
      clientUserId: json['clientUserId'] as String?,
      clientName: json['clientName'] as String? ?? 'Público General',
      discountAmount: (json['discountAmount'] as num? ?? 0).toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      items: rawItems
          .map((e) => CreateSaleDetailInnerDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

/// Servicio para pausar y recuperar carritos ("Tickets en Espera") respaldado en Isar.
class HeldCartsService {
  static const String _cacheKey = 'offline_sales_queue_held_carts_v1';

  static final ValueNotifier<List<HeldCartTicket>> heldCartsNotifier =
      ValueNotifier<List<HeldCartTicket>>([]);

  static Future<void> init() async {
    try {
      final raw = await IsarCacheService.getCache(_cacheKey);
      if (raw == null || raw.isEmpty) {
        heldCartsNotifier.value = [];
        return;
      }
      final decoded = jsonDecode(raw) as List<dynamic>;
      heldCartsNotifier.value = decoded
          .map((e) => HeldCartTicket.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      AppLogger.warning('Error cargando tickets en espera desde Isar: $e');
    }
  }

  static Future<void> _persist(List<HeldCartTicket> list) async {
    heldCartsNotifier.value = List.unmodifiable(list);
    try {
      await IsarCacheService.saveCache(
        _cacheKey,
        jsonEncode(list.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      AppLogger.warning('Error guardando tickets en espera en Isar: $e');
    }
  }

  static List<HeldCartTicket> forBusiness(String businessId) {
    return heldCartsNotifier.value.where((t) => t.businessId == businessId).toList();
  }

  static Future<HeldCartTicket> parkCart({
    required String businessId,
    required List<CreateSaleDetailInnerDto> items,
    String? label,
    String? clientUserId,
    String clientName = 'Público General',
    double discountAmount = 0.0,
    String? notes,
  }) async {
    final existingForBusiness = forBusiness(businessId);
    final ticketNumber = existingForBusiness.length + 1;
    final cleanLabel = (label != null && label.trim().isNotEmpty)
        ? label.trim()
        : (clientName != 'Público General' && clientName.trim().isNotEmpty
            ? clientName.trim()
            : 'Cliente #$ticketNumber');

    final ticket = HeldCartTicket(
      id: const Uuid().v4(),
      businessId: businessId,
      label: cleanLabel,
      clientUserId: clientUserId,
      clientName: clientName.isEmpty ? 'Público General' : clientName,
      discountAmount: discountAmount,
      notes: notes,
      createdAt: DateTime.now(),
      items: items,
    );

    final updated = [ticket, ...heldCartsNotifier.value];
    await _persist(updated);
    return ticket;
  }

  static Future<void> removeTicket(String id) async {
    final updated = heldCartsNotifier.value.where((t) => t.id != id).toList();
    await _persist(updated);
  }
}
