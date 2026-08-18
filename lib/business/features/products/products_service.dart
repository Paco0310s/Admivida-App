import 'package:admivida/business/features/add_product/models/add_product_model.dart';
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

  static Future<EitherUtil<HttpFailure, ProductModel>> createProduct(CreateProductDto dto) async {
    return await DioService.post<ProductModel>('/products', dto.toJson(), (data) => ProductModel.fromJson(data));
  }

  /// Updates a full product including its variants and images
  // static Future<EitherUtil<HttpFailure, Product>> updateProduct({
  //   required String productId,
  //   required String businessId,
  //   required Map<String, dynamic> updateProductData, // Contains the UpdateProductDto payload
  // }) async {
  //   final Map<String, dynamic> queryParams = {'businessId': businessId};

  //   final String endpoint = '${AppConfig.productsEndpoint}/$productId';

  //   final response = await DioService.put<Product>(
  //     endpoint,
  //     (json) => Product.fromJson(json), // Maps the backend response back to your Product model
  //     data: updateProductData,
  //     queryParameters: queryParams,
  //   );

  //   return response.when((failure) => EitherUtil.failure(failure), (product) => EitherUtil.success(product));
  // }

  // /// Updates only the stock quantity for a specific variant
  // static Future<EitherUtil<HttpFailure, ProductVariant>> updateVariantStock({
  //   required String variantId,
  //   required String businessId,
  //   required double newStockQuantity,
  // }) async {
  //   final Map<String, dynamic> queryParams = {'businessId': businessId};

  //   final Map<String, dynamic> payload = {'stockQuantity': newStockQuantity};

  //   // Constructs the path: /products/variants/:variantId/stock
  //   final String endpoint = '${AppConfig.productsEndpoint}/variants/$variantId/stock';

  //   final response = await DioService.patch<ProductVariant>(
  //     endpoint,
  //     (json) => ProductVariant.fromJson(json), // Maps the updated variant back
  //     data: payload,
  //     queryParameters: queryParams,
  //   );

  //   return response.when((failure) => EitherUtil.failure(failure), (variant) => EitherUtil.success(variant));
  // }
}
