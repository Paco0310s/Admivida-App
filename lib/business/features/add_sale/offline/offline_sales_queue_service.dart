import 'dart:async';
import 'dart:convert';

import 'package:admivida/business/features/add_sale/cart/cart_service.dart';
import 'package:admivida/business/features/add_sale/cart/models/create_sale_dto.dart';
import 'package:admivida/business/features/add_sale/models/create_sale_detail_inner_dto.dart';
import 'package:admivida/business/features/add_sale/models/scanned_variant_model.dart';
import 'package:admivida/business/features/products/models/product_model.dart';
import 'package:admivida/business/features/sales/models/sale_model.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/logging/app_logger.dart';
import 'package:admivida/common/services/connectivity_service.dart';
import 'package:admivida/common/services/isar_cache_service.dart';
import 'package:admivida/common/utils/globals.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class PendingOfflineSale {
  final String localId;
  final String businessId;
  final String businessName;
  final String sellerName;
  final DateTime createdAt;
  final CreateSaleDto dto;
  final SaleModel previewSale;
  final int syncAttempts;
  final String? lastError;
  final bool requiresAttention;

  const PendingOfflineSale({
    required this.localId,
    required this.businessId,
    required this.businessName,
    required this.sellerName,
    required this.createdAt,
    required this.dto,
    required this.previewSale,
    this.syncAttempts = 0,
    this.lastError,
    this.requiresAttention = false,
  });

  PendingOfflineSale copyWith({
    int? syncAttempts,
    String? lastError,
    bool? requiresAttention,
  }) {
    return PendingOfflineSale(
      localId: localId,
      businessId: businessId,
      businessName: businessName,
      sellerName: sellerName,
      createdAt: createdAt,
      dto: dto,
      previewSale: previewSale,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      lastError: lastError,
      requiresAttention: requiresAttention ?? this.requiresAttention,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'localId': localId,
      'businessId': businessId,
      'businessName': businessName,
      'sellerName': sellerName,
      'createdAt': createdAt.toIso8601String(),
      'dto': {
        ...dto.toJson(),
        'details': dto.details.map((d) => d.toLocalJson()).toList(),
        if (dto.payments != null && dto.payments!.isNotEmpty)
          'payments': dto.payments!.map((p) => p.toLocalJson()).toList(),
      },
      'previewSale': previewSale.toJson(),
      'syncAttempts': syncAttempts,
      'lastError': lastError,
      'requiresAttention': requiresAttention,
    };
  }

  factory PendingOfflineSale.fromJson(Map<String, dynamic> json) {
    final dtoMap = Map<String, dynamic>.from(json['dto'] as Map);
    final previewMap = Map<String, dynamic>.from(json['previewSale'] as Map);
    return PendingOfflineSale(
      localId: json['localId'] as String? ?? '',
      businessId: json['businessId'] as String? ?? '',
      businessName: json['businessName'] as String? ?? '',
      sellerName: json['sellerName'] as String? ?? 'Cajero',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      dto: CreateSaleDto.fromJson(dtoMap),
      previewSale: SaleModel.fromJson(previewMap),
      syncAttempts: json['syncAttempts'] as int? ?? 0,
      lastError: json['lastError'] as String?,
      requiresAttention: json['requiresAttention'] as bool? ?? false,
    );
  }
}

/// Servicio encargado de:
/// 1. Guardar la cola de ventas en Isar cuando no hay conexión a internet.
/// 2. Sincronizar automáticamente en orden cronológico (FIFO) al volver la conexión.
/// 3. Mantener un catálogo local consolidado en Isar para búsqueda y escaneo de códigos de barras offline.
class OfflineSalesQueueService {
  static const String _queueCacheKey = 'offline_sales_queue_v1';
  static String _catalogKey(String businessId) => 'offline_pos_catalog_$businessId';
  static String _catalogSyncAtKey(String businessId) => 'offline_pos_catalog_sync_at_$businessId';

  static final ValueNotifier<List<PendingOfflineSale>> queueNotifier =
      ValueNotifier<List<PendingOfflineSale>>([]);
  static final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);
  static final ValueNotifier<bool> isCatalogSyncingNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<Map<String, int>> catalogCountByBusinessNotifier =
      ValueNotifier<Map<String, int>>({});

  static final StreamController<String> _syncedBusinessController =
      StreamController<String>.broadcast();

  /// Emite el `businessId` cada vez que se sincronizan ventas pendientes de ese negocio.
  static Stream<String> get onBusinessSynced => _syncedBusinessController.stream;

  static StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  static bool _initialized = false;

  /// Inicializa la lectura de la cola local y arranca el listener reactivo de red (sin timers de polling).
  static Future<void> init() async {
    await loadQueue();
    if (_initialized) return;
    _initialized = true;

    // Por defecto asumimos conectado; si hay ventas pendientes al abrir la app, intentamos sincronizarlas
    if (queueNotifier.value.isNotEmpty) {
      unawaited(syncPendingSales());
    }

    // Escuchar únicamente eventos reales de cambio de red del sistema operativo
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) async {
      final hasAnyActiveAdapter = results.any((r) => r != ConnectivityResult.none);
      if (!hasAnyActiveAdapter) {
        // En Windows con adaptadores virtuales puede reportar none falsamente; verificamos antes de marcar sin red
        final stillOnline = await ConnectivityService.hasInternet();
        isOnlineNotifier.value = stillOnline;
        return;
      }

      // Pequeña espera para que el enlace DNS/TCP se estabilice al reconectar Wi-Fi/Datos
      await Future.delayed(const Duration(milliseconds: 900));
      final online = await ConnectivityService.hasInternet();
      if (online) {
        notifyNetworkSuccess();
      }
    });
  }

  /// Llamado automáticamente cuando cualquier petición HTTP al servidor responde con éxito.
  /// Restablece el estado en línea al instante y sincroniza la cola si había ventas pendientes.
  static void notifyNetworkSuccess() {
    if (!isOnlineNotifier.value) {
      isOnlineNotifier.value = true;
    }
    if (queueNotifier.value.isNotEmpty && !isSyncingNotifier.value) {
      final hasAutoSyncable = queueNotifier.value.any((s) => !s.requiresAttention);
      if (hasAutoSyncable) {
        unawaited(syncPendingSales());
      }
    }
  }

  static void dispose() {
    _connectivitySubscription?.cancel();
  }

  /// Carga la cola persistida en Isar
  static Future<List<PendingOfflineSale>> loadQueue() async {
    try {
      final raw = await IsarCacheService.getCache(_queueCacheKey);
      if (raw == null || raw.isEmpty) {
        queueNotifier.value = [];
        return [];
      }
      final decoded = jsonDecode(raw) as List<dynamic>;
      final list = decoded
          .map((item) => PendingOfflineSale.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
      queueNotifier.value = list;
      return list;
    } catch (e) {
      AppLogger.error('Error cargando cola de ventas offline desde Isar: $e');
      return queueNotifier.value;
    }
  }

  static Future<void> _persistQueue(List<PendingOfflineSale> list) async {
    queueNotifier.value = List.unmodifiable(list);
    try {
      final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
      await IsarCacheService.saveCache(_queueCacheKey, encoded);
    } catch (e) {
      AppLogger.error('Error guardando cola de ventas offline en Isar: $e');
    }
  }

  /// Obtiene las ventas pendientes de un negocio específico
  static List<PendingOfflineSale> pendingForBusiness(String businessId) {
    return queueNotifier.value.where((s) => s.businessId == businessId).toList();
  }

  /// Indica si un fallo HTTP corresponde a falta de red o timeout (seguro para encolar offline).
  static bool isOfflineOrTimeoutFailure(HttpFailure failure) {
    return failure.type == 'CONNECTION_ERROR' ||
        failure.type == 'CONNECTION_TIMEOUT_ERROR' ||
        failure.type == 'SEND_TIMEOUT_ERROR' ||
        failure.type == 'RECEIVE_TIMEOUT_ERROR' ||
        failure.type == 'TIMEOUT';
  }

  /// Durante la sincronización, solo reintenta automáticamente en fallos de red/timeout o errores 5xx del servidor.
  /// Un error 4xx (stock insuficiente, datos inválidos, etc.) marca la venta con `requiresAttention = true`.
  static bool isTransientSyncFailure(HttpFailure failure) {
    if (isOfflineOrTimeoutFailure(failure)) return true;
    if (failure.type == 'SERVER_ERROR') {
      final code = failure.statusCode;
      return code == null || code == 0 || code >= 500;
    }
    return false;
  }

  /// Encola una nueva venta cuando no hay conexión a internet y devuelve el [PendingOfflineSale]
  /// con su [SaleModel] listo para imprimir ticket térmico y abrir cajón.
  static Future<PendingOfflineSale> enqueueSale({
    required CreateSaleDto dto,
    required String businessName,
    required String sellerName,
  }) async {
    final now = dto.soldAt ?? DateTime.now();
    final shortCode = const Uuid().v4().substring(0, 6).toUpperCase();
    final localId = 'OFFLINE-$shortCode';

    final dtoWithTimestamp = CreateSaleDto(
      businessId: dto.businessId,
      sellerUserId: dto.sellerUserId,
      accountId: dto.accountId,
      paymentMethodId: dto.paymentMethodId,
      clientUserId: dto.clientUserId,
      clientNameSnapshot: dto.clientNameSnapshot,
      status: dto.status,
      discountAmount: dto.discountAmount,
      amountPaid: dto.amountPaid,
      notes: dto.notes,
      latitude: dto.latitude,
      longitude: dto.longitude,
      soldAt: now,
      details: dto.details,
      payments: dto.payments,
    );

    final subtotal = dto.details.fold<double>(
      0.0,
      (sum, d) => sum + (d.isPaid ? (d.unitPrice * d.quantity) : 0.0),
    );
    final finalTotal = (subtotal - dto.discountAmount).clamp(0.0, double.infinity);
    final changeGiven = dto.amountPaid > finalTotal ? (dto.amountPaid - finalTotal) : 0.0;

    final saleDetails = dto.details.map((d) {
      return SaleDetailModel(
        id: d.id,
        saleId: localId,
        productVariantId: d.productVariantId,
        productId: null,
        productNameSnapshot: d.productNameSnapshot,
        quantity: d.quantity,
        originalPriceSnapshot: d.originalPriceSnapshot,
        productPriceSnapshot: d.unitPrice,
        productCostSnapshot: null,
        priceType: d.priceType,
        commentary: d.commentary,
        isPaid: d.isPaid,
        sellerComissionSnapshot: 0,
        isComissionPaid: false,
        createdAt: now,
        updatedAt: now,
        subtotal: d.unitPrice * d.quantity,
        imageUrl: d.imageUrl,
      );
    }).toList();

    final previewSale = SaleModel(
      id: localId,
      businessId: dto.businessId,
      sellerUserId: dto.sellerUserId,
      sellerName: sellerName,
      clientUserId: dto.clientUserId,
      clientNameSnapshot: dto.clientNameSnapshot.isEmpty ? 'Público General' : dto.clientNameSnapshot,
      status: dto.status,
      discountAmount: dto.discountAmount,
      amountPaid: dto.amountPaid,
      changeGiven: changeGiven,
      totalPriceSnapshot: finalTotal,
      notes: dto.notes,
      latitude: dto.latitude,
      longitude: dto.longitude,
      details: saleDetails,
      payments: (dto.payments ?? const [])
          .map(
            (p) => SalePaymentModel(
              paymentMethodId: p.paymentMethodId,
              paymentMethodName: p.paymentMethodName ?? 'Pago',
              paymentMethodCode: 'OTHER',
              amount: p.amount,
            ),
          )
          .toList(),
      createdAt: now,
      updatedAt: now,
    );

    final pending = PendingOfflineSale(
      localId: localId,
      businessId: dto.businessId,
      businessName: businessName,
      sellerName: sellerName,
      createdAt: now,
      dto: dtoWithTimestamp,
      previewSale: previewSale,
    );

    final updated = [...queueNotifier.value, pending];
    await _persistQueue(updated);
    isOnlineNotifier.value = false;

    // Descontar existencias localmente en el catálogo Isar para que el cajero vea el stock actualizado
    await deductLocalCatalogStock(dto.businessId, dto.details);

    AppLogger.info('📦 Venta guardada en cola offline Isar ($localId) - Total: \$$finalTotal');
    return pending;
  }

  /// Elimina manualmente una venta de la cola offline y restaura su stock en el catálogo local de Isar
  static Future<void> removePendingSale(String localId) async {
    final removed = queueNotifier.value.where((s) => s.localId == localId).firstOrNull;
    final updated = queueNotifier.value.where((s) => s.localId != localId).toList();
    await _persistQueue(updated);
    if (removed != null) {
      await _adjustLocalCatalogStock(removed.businessId, removed.dto.details, restore: true);
    }
  }

  /// Sincroniza todas las ventas en cola con el servidor en orden FIFO.
  /// Si [forceRetryAll] es true, reintenta incluso aquellas marcadas con error previo.
  static Future<int> syncPendingSales({bool forceRetryAll = false}) async {
    if (isSyncingNotifier.value) return 0;
    final currentQueue = List<PendingOfflineSale>.from(queueNotifier.value);
    if (currentQueue.isEmpty) return 0;

    final online = await ConnectivityService.hasInternet();
    isOnlineNotifier.value = online;
    if (!online) return 0;

    isSyncingNotifier.value = true;
    int syncedCount = 0;
    final Set<String> syncedBusinesses = {};
    final List<PendingOfflineSale> remaining = [];

    try {
      for (int i = 0; i < currentQueue.length; i++) {
        final item = currentQueue[i];

        if (item.requiresAttention && !forceRetryAll) {
          remaining.add(item);
          continue;
        }

        final result = await CartService.createSale(item.dto);
        bool stopDueToOffline = false;

        result.when(
          (failure) {
            if (isTransientSyncFailure(failure)) {
              // Se volvió a caer la conexión o el servidor respondió 5xx; conservamos el resto intacto
              if (isOfflineOrTimeoutFailure(failure)) {
                isOnlineNotifier.value = false;
              }
              remaining.add(
                item.copyWith(
                  syncAttempts: item.syncAttempts + 1,
                  lastError: failure.message,
                  requiresAttention: false,
                ),
              );
              stopDueToOffline = true;
            } else {
              // Error de validación del negocio (ej. stock insuficiente o caja cerrada)
              remaining.add(
                item.copyWith(
                  syncAttempts: item.syncAttempts + 1,
                  lastError: failure.message,
                  requiresAttention: true,
                ),
              );
            }
          },
          (syncedSale) {
            syncedCount++;
            syncedBusinesses.add(item.businessId);
            AppLogger.info('✅ Venta offline ${item.localId} sincronizada como ${syncedSale.id}');
          },
        );

        if (stopDueToOffline) {
          // Agregar las ventas restantes sin tocarlas
          if (i + 1 < currentQueue.length) {
            remaining.addAll(currentQueue.sublist(i + 1));
          }
          break;
        }
      }

      await _persistQueue(remaining);

      if (syncedCount > 0) {
        for (final bId in syncedBusinesses) {
          _syncedBusinessController.add(bId);
        }
        _showSyncBannerNotification(syncedCount, remaining.length);
      }
    } catch (e) {
      AppLogger.error('Error inesperado sincronizando cola de ventas offline: $e');
    } finally {
      isSyncingNotifier.value = false;
    }

    return syncedCount;
  }

  static void _showSyncBannerNotification(int syncedCount, int pendingCount) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    final label = syncedCount == 1
        ? '1 venta offline se sincronizó automáticamente con el servidor.'
        : '$syncedCount ventas offline se sincronizaron automáticamente con el servidor.';

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F766E),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                pendingCount > 0 ? '$label ($pendingCount pendiente(s) por revisar)' : label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // CATÁLOGO LOCAL EN ISAR PARA BÚSQUEDA Y ESCANEO DE CÓDIGOS DE BARRAS OFFLINE
  // ===========================================================================

  static void _updateCatalogCount(String businessId, int count) {
    final next = Map<String, int>.from(catalogCountByBusinessNotifier.value);
    next[businessId] = count;
    catalogCountByBusinessNotifier.value = next;
  }

  /// Reemplaza el catálogo local completo tras una sincronización multipágina exitosa.
  static Future<void> replaceLocalCatalogProducts(
    String businessId,
    List<ProductModel> products,
  ) async {
    try {
      final Map<String, ProductModel> uniqueById = {
        for (final p in products) p.id: p,
      };
      final encoded = jsonEncode(uniqueById.values.map((e) => e.toJson()).toList());
      await IsarCacheService.saveCache(_catalogKey(businessId), encoded);
      await IsarCacheService.saveCache(_catalogSyncAtKey(businessId), DateTime.now().toIso8601String());
      _updateCatalogCount(businessId, uniqueById.length);
    } catch (e) {
      AppLogger.warning('No se pudo reemplazar el catálogo offline: $e');
    }
  }

  static Future<DateTime?> getLastCatalogSyncAt(String businessId) async {
    try {
      final raw = await IsarCacheService.getCache(_catalogSyncAtKey(businessId));
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw)?.toLocal();
    } catch (_) {
      return null;
    }
  }

  /// Guarda o fusiona productos dentro del catálogo local para un negocio.
  static Future<void> upsertLocalCatalogProducts(
    String businessId,
    List<ProductModel> products,
  ) async {
    if (products.isEmpty) return;
    try {
      final existing = await getLocalCatalogProducts(businessId);
      final Map<String, ProductModel> byId = {
        for (final p in existing) p.id: p,
      };
      for (final p in products) {
        byId[p.id] = p;
      }
      final encoded = jsonEncode(byId.values.map((e) => e.toJson()).toList());
      await IsarCacheService.saveCache(_catalogKey(businessId), encoded);
      _updateCatalogCount(businessId, byId.length);
    } catch (e) {
      AppLogger.warning('No se pudo actualizar el catálogo offline: $e');
    }
  }

  /// Obtiene todos los productos guardados localmente para el negocio.
  static Future<List<ProductModel>> getLocalCatalogProducts(String businessId) async {
    try {
      final raw = await IsarCacheService.getCache(_catalogKey(businessId));
      if (raw == null || raw.isEmpty) {
        _updateCatalogCount(businessId, 0);
        return [];
      }
      final decoded = jsonDecode(raw) as List<dynamic>;
      final list = decoded
          .map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
      _updateCatalogCount(businessId, list.length);
      return list;
    } catch (e) {
      AppLogger.warning('Error leyendo catálogo offline: $e');
      return [];
    }
  }

  /// Filtra y pagina localmente los productos en Isar cuando no hay internet.
  static Future<ProductsPageModel?> searchLocalCatalog(
    String businessId, {
    int page = 1,
    int limit = 12,
    String? nameOrSku,
  }) async {
    final allProducts = await getLocalCatalogProducts(businessId);
    if (allProducts.isEmpty) return null;

    final query = (nameOrSku ?? '').trim().toLowerCase();
    final tokens = query.isEmpty ? const <String>[] : query.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    final filtered = tokens.isEmpty
        ? allProducts
        : allProducts.where((product) {
            final searchableParts = <String>[
              product.name.toLowerCase(),
              (product.description ?? '').toLowerCase(),
              for (final v in product.variants) ...[
                (v.name ?? '').toLowerCase(),
                (v.sku ?? '').toLowerCase(),
                (v.barcode ?? '').toLowerCase(),
              ],
            ];
            final combined = searchableParts.join(' ');
            return tokens.every((token) => combined.contains(token));
          }).toList();

    final totalItems = filtered.length;
    final totalPages = totalItems == 0 ? 1 : ((totalItems + limit - 1) ~/ limit);
    final safePage = page.clamp(1, totalPages);
    final startIndex = (safePage - 1) * limit;
    final pageItems = startIndex >= totalItems
        ? <ProductModel>[]
        : filtered.skip(startIndex).take(limit).toList();

    return ProductsPageModel(
      data: pageItems,
      meta: ProductsMetaModel(
        totalItems: totalItems,
        itemCount: pageItems.length,
        itemsPerPage: limit,
        totalPages: totalPages,
        currentPage: safePage,
      ),
    );
  }

  /// Busca una variante por código de barras o SKU en el catálogo local de Isar cuando no hay internet.
  static Future<ScannedVariantModel?> findVariantByCodeOffline(
    String businessId,
    String code,
  ) async {
    final cleanCode = code.trim().toLowerCase();
    if (cleanCode.isEmpty) return null;

    final allProducts = await getLocalCatalogProducts(businessId);
    for (final product in allProducts) {
      for (final variant in product.variants) {
        final barcodeMatch = (variant.barcode ?? '').trim().toLowerCase() == cleanCode;
        final skuMatch = (variant.sku ?? '').trim().toLowerCase() == cleanCode;
        if (barcodeMatch || skuMatch) {
          final variantName = (variant.name != null && variant.name!.trim().isNotEmpty)
              ? '${product.name} - ${variant.name}'
              : product.name;
          final images = variant.images.isNotEmpty
              ? variant.images.map((i) => i.url).toList()
              : product.images.map((i) => i.url).toList();

          return ScannedVariantModel(
            id: variant.id,
            productId: product.id,
            sku: variant.sku,
            barcode: variant.barcode,
            name: variantName,
            purchasePrice: variant.purchasePrice ?? 0.0,
            salePrice: variant.salePrice,
            wholesalePrice: variant.wholesalePrice,
            wholesaleQuantity: variant.wholesaleQuantity,
            stockQuantity: variant.stockQuantity ?? 0.0,
            minimumStock: variant.minimumStock,
            maximumStock: variant.maximumStock,
            expirationDate: variant.expirationDate,
            attributes: variant.attributes,
            images: images,
            allowFractions: product.allowsFractionalQuantity,
            createdAt: variant.createdAt,
            updatedAt: variant.updatedAt,
          );
        }
      }
    }
    return null;
  }

  /// Descuenta localmente el stock de las variantes vendidas en modo offline.
  static Future<void> deductLocalCatalogStock(
    String businessId,
    List<CreateSaleDetailInnerDto> details,
  ) =>
      _adjustLocalCatalogStock(businessId, details, restore: false);

  static Future<void> _adjustLocalCatalogStock(
    String businessId,
    List<CreateSaleDetailInnerDto> details, {
    required bool restore,
  }) async {
    try {
      final allProducts = await getLocalCatalogProducts(businessId);
      if (allProducts.isEmpty) return;

      final Map<String, double> qtyByVariant = {};
      for (final d in details) {
        qtyByVariant[d.productVariantId] = (qtyByVariant[d.productVariantId] ?? 0) + d.quantity;
      }

      bool changed = false;
      final updatedProducts = allProducts.map((product) {
        bool productChanged = false;
        final updatedVariants = product.variants.map((variant) {
          final delta = qtyByVariant[variant.id];
          if (delta != null && variant.stockQuantity != null) {
            productChanged = true;
            changed = true;
            final newStock = restore
                ? (variant.stockQuantity! + delta)
                : (variant.stockQuantity! - delta).clamp(0.0, double.infinity);
            return variant.copyWith(stockQuantity: newStock);
          }
          return variant;
        }).toList();

        return productChanged ? product.copyWith(variants: updatedVariants) : product;
      }).toList();

      if (changed) {
        final encoded = jsonEncode(updatedProducts.map((e) => e.toJson()).toList());
        await IsarCacheService.saveCache(_catalogKey(businessId), encoded);
      }
    } catch (e) {
      AppLogger.warning('Error ajustando stock local en Isar: $e');
    }
  }
}
