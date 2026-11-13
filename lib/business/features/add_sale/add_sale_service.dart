import 'dart:async';

import 'package:admivida/business/features/add_sale/cart/models/create_sale_dto.dart';
import 'package:admivida/business/features/add_sale/models/scanned_variant_model.dart';
import 'package:admivida/business/features/add_sale/offline/offline_sales_queue_service.dart';
import 'package:admivida/business/features/products/models/product_model.dart';
import 'package:admivida/business/features/sales/models/sale_model.dart';
import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/services/connectivity_service.dart';
import 'package:admivida/common/services/dio_service.dart';
import 'package:admivida/common/utils/either.dart';

class AddSaleService {
  static final Set<String> _warmedUpBusinesses = {};

  static Future<EitherUtil<HttpFailure, SaleModel>> createSale(CreateSaleDto dto) async {
    final response = await DioService.post<SaleModel>(AppConfig.createSaleEndpoint, dto.toJson(), (json) => SaleModel.fromJson(json));
    return response.when((failure) => EitherUtil.failure(failure), (saleModel) => EitherUtil.success(saleModel));
  }

  static Future<EitherUtil<HttpFailure, ProductsPageModel>> getTenantProducts(
    String businessId, {
    required int page,
    required int limit,
    String? nameOrSku,
  }) async {
    final bool hasNet = OfflineSalesQueueService.isOnlineNotifier.value && await ConnectivityService.hasInternet();
    if (!hasNet) {
      final localPage = await OfflineSalesQueueService.searchLocalCatalog(
        businessId,
        page: page,
        limit: limit,
        nameOrSku: nameOrSku,
      );
      if (localPage != null) {
        return EitherUtil.success(localPage);
      }
      return EitherUtil.failure(HttpFailure(message: 'Sin conexión a internet y sin catálogo guardado localmente'));
    }

    final Map<String, dynamic> queryParams = {'page': page, 'limit': limit, 'isActive': true};

    if (nameOrSku != null && nameOrSku.trim().isNotEmpty) {
      queryParams['search'] = nameOrSku.trim();
    }

    final response = await DioService.get<ProductsPageModel>(
      AppConfig.productsTenantEndpoint(businessId),
      (json) => ProductsPageModel.fromJson(json),
      queryParameters: queryParams,
    );

    return await response.when(
      (failure) async {
        // Fallback 100% offline usando el catálogo local consolidado
        final localPage = await OfflineSalesQueueService.searchLocalCatalog(
          businessId,
          page: page,
          limit: limit,
          nameOrSku: nameOrSku,
        );
        if (localPage != null) {
          return EitherUtil.success(localPage);
        }
        return EitherUtil.failure(failure);
      },
      (pageResponse) async {
        unawaited(OfflineSalesQueueService.upsertLocalCatalogProducts(businessId, pageResponse.data));
        if (page == 1 && (nameOrSku == null || nameOrSku.trim().isEmpty) && !_warmedUpBusinesses.contains(businessId)) {
          _warmedUpBusinesses.add(businessId);
          unawaited(syncFullCatalogForOffline(businessId));
        }
        return EitherUtil.success(pageResponse);
      },
    );
  }

  /// Descarga todas las páginas de productos activos del negocio y las guarda localmente
  /// para que el buscador y el lector de códigos de barras funcionen 100% sin internet.
  static Future<int?> syncFullCatalogForOffline(String businessId) async {
    if (OfflineSalesQueueService.isCatalogSyncingNotifier.value) return null;
    OfflineSalesQueueService.isCatalogSyncingNotifier.value = true;
    try {
      if (!await ConnectivityService.hasInternet()) return null;

      final List<ProductModel> allProducts = [];
      int currentPage = 1;
      int totalPages = 1;

      do {
        final res = await DioService.get<ProductsPageModel>(
          AppConfig.productsTenantEndpoint(businessId),
          (json) => ProductsPageModel.fromJson(json),
          queryParameters: {'page': currentPage, 'limit': 100, 'isActive': true},
        );

        bool pageOk = false;
        res.when(
          (_) {},
          (pageModel) {
            pageOk = true;
            allProducts.addAll(pageModel.data);
            totalPages = pageModel.meta?.totalPages ?? 1;
          },
        );

        if (!pageOk) break;
        currentPage++;
      } while (currentPage <= totalPages && currentPage <= 50);

      if (allProducts.isNotEmpty) {
        await OfflineSalesQueueService.replaceLocalCatalogProducts(businessId, allProducts);
        return allProducts.length;
      }
      return 0;
    } catch (_) {
      return null;
    } finally {
      OfflineSalesQueueService.isCatalogSyncingNotifier.value = false;
    }
  }

  static Future<EitherUtil<HttpFailure, ScannedVariantModel>> scanProductVariant({required String sku, required String businessId}) async {
    final bool hasNet = OfflineSalesQueueService.isOnlineNotifier.value && await ConnectivityService.hasInternet();
    if (!hasNet) {
      final offlineVariant = await OfflineSalesQueueService.findVariantByCodeOffline(businessId, sku);
      if (offlineVariant != null) {
        return EitherUtil.success(offlineVariant);
      }
      return EitherUtil.failure(HttpFailure(message: 'Producto no encontrado en el catálogo sin internet'));
    }

    final response = await DioService.get<ScannedVariantModel>(
      AppConfig.productVariantScanEndpoint(sku),
      queryParameters: {'businessId': businessId},
      (json) => ScannedVariantModel.fromJson(json),
    );

    return await response.when(
      (failure) async {
        // Si falla la red, buscar instantáneamente en el catálogo local
        final offlineVariant = await OfflineSalesQueueService.findVariantByCodeOffline(businessId, sku);
        if (offlineVariant != null) {
          return EitherUtil.success(offlineVariant);
        }
        return EitherUtil.failure(failure);
      },
      (scannedVariant) async => EitherUtil.success(scannedVariant),
    );
  }
}
