// import 'package:admivida/business/features/add_product/models/add_product_model.dart';
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
  }) async {
    // final Map<String, dynamic> queryParams = {'page': page, 'limit': limit, 'isActive': true, 'stockGreaterThan': 0};
    final Map<String, dynamic> queryParams = {'page': page, 'limit': limit};

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final response = await DioService.get<ProductsPageModel>(
      AppConfig.productsTenantEndpoint(businessId),
      (json) => ProductsPageModel.fromJson(json),
      queryParameters: queryParams,
    );

    return response.when((failure) => EitherUtil.failure(failure), (pageResponse) => EitherUtil.success(pageResponse));
  }

  static Future<EitherUtil<HttpFailure, void>> updateStock(String businessId, String variantId, double newStock) async {
    final response = await DioService.patch<void>(
      AppConfig.updateStockProductVariantEndpoint(variantId),
      {'stockQuantity': newStock},
      (_) {},
      queryParameters: {'businessId': businessId},
    );

    return response.when((failure) => EitherUtil.failure(failure), (_) => EitherUtil.success(null));
  }

  static Future<EitherUtil<HttpFailure, ProductModel>> getProductById({required String businessId, required String productId}) async {
    final response = await DioService.get<ProductModel>(AppConfig.getProductByIdEndpoint(productId, businessId), (json) => ProductModel.fromJson(json));

    return response.when((failure) => EitherUtil.failure(failure), (product) => EitherUtil.success(product));
  }
}
