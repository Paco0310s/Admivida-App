// import 'package:admivida/business/features/add_product/models/add_product_model.dart';
import 'package:admivida/business/features/products/models/inventory_movement_model.dart';
import 'package:admivida/business/features/products/models/product_model.dart';
import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/services/dio_service.dart';
import 'package:admivida/common/utils/either.dart';

class ProductsService {
  static Future<EitherUtil<HttpFailure, ProductsPageModel>> getTenantProducts({
    required int page,
    required int limit,
    required String businessId,
    String? search,
    String? categoryId,
    bool? isActive,
    String? stockStatus,
  }) async {
    final Map<String, dynamic> queryParams = {'page': page, 'limit': limit};

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      queryParams['categoryId'] = categoryId;
    }
    if (isActive != null) {
      queryParams['isActive'] = isActive.toString();
    }
    if (stockStatus != null && stockStatus.isNotEmpty) {
      queryParams['stockStatus'] = stockStatus;
    }

    final response = await DioService.get<ProductsPageModel>(
      AppConfig.productsTenantEndpoint(businessId),
      (json) => ProductsPageModel.fromJson(json),
      queryParameters: queryParams,
    );

    return response.when((failure) => EitherUtil.failure(failure), (pageResponse) => EitherUtil.success(pageResponse));
  }

  static Future<EitherUtil<HttpFailure, void>> updateStock(
    String businessId,
    String variantId,
    double newStock, {
    String? reason,
    String? notes,
    String? reference,
  }) async {
    final payload = <String, dynamic>{
      'stockQuantity': newStock,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      if (reference != null && reference.trim().isNotEmpty) 'reference': reference.trim(),
    };

    final response = await DioService.patch<void>(
      AppConfig.updateStockProductVariantEndpoint(variantId),
      payload,
      (_) {},
      queryParameters: {'businessId': businessId},
    );

    return response.when((failure) => EitherUtil.failure(failure), (_) => EitherUtil.success(null));
  }

  static Future<EitherUtil<HttpFailure, List<InventoryMovementModel>>> getProductMovements({
    required String businessId,
    required String productId,
    int limit = 25,
  }) async {
    final response = await DioService.getList<InventoryMovementModel>(
      AppConfig.inventoryMovementsEndpoint(businessId),
      (json) => InventoryMovementModel.fromJson(json),
      queryParameters: {
        'productId': productId,
        'limit': limit,
      },
    );

    return response.when((failure) => EitherUtil.failure(failure), (items) => EitherUtil.success(items));
  }

  static Future<EitherUtil<HttpFailure, ProductModel>> getProductById({required String businessId, required String productId}) async {
    final response = await DioService.get<ProductModel>(AppConfig.getProductByIdEndpoint(productId, businessId), (json) => ProductModel.fromJson(json));

    return response.when((failure) => EitherUtil.failure(failure), (product) => EitherUtil.success(product));
  }

  static Future<EitherUtil<HttpFailure, bool>> deleteProduct({
    required String businessId,
    required String productId,
  }) async {
    final response = await DioService.delete(
      AppConfig.deleteProductEndpoint(productId, businessId),
      queryParameters: {'businessId': businessId},
    );

    return response;
  }
}