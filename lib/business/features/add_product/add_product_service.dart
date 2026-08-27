import 'package:admivida/business/features/add_product/models/create_product_dto.dart';
import 'package:admivida/business/features/add_product/models/product_category_model.dart';
import 'package:admivida/business/features/add_product/models/product_type_model.dart';
import 'package:admivida/business/features/add_product/models/update_product_dto.dart';
import 'package:admivida/business/features/products/models/product_model.dart';
import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/services/dio_service.dart';
import 'package:admivida/common/utils/either.dart';

class AddProductService {
  /// Retrieves the master list of available Product Types (e.g., Físico, Servicio).
  static Future<EitherUtil<HttpFailure, List<ProductTypeModel>>> getProductTypes() async {
    return await DioService.getList<ProductTypeModel>(AppConfig.productTypesEndpoint, ProductTypeModel.fromJson);
  }

  // En tu ProductsService de Flutter:
  static Future<EitherUtil<HttpFailure, List<ProductCategoryModel>>> getTenantCategories(String businessId) async {
    return await DioService.getList<ProductCategoryModel>(AppConfig.productCategoriesEndpoint(businessId), ProductCategoryModel.fromJson);
  }

  static Future<EitherUtil<HttpFailure, ProductModel>> createProduct(CreateProductDto dto) async {
    return await DioService.post<ProductModel>(AppConfig.createProductEndpoint, dto.toJson(), (data) => ProductModel.fromJson(data));
  }

  static Future<EitherUtil<HttpFailure, ProductModel>> updateProduct({
    required String productId,
    required String businessId,
    required UpdateProductDto dto,
  }) async {
    final endpoint = AppConfig.updateProductEndpoint(productId);

    return await DioService.put<ProductModel>(endpoint, dto.toJson(), (data) => ProductModel.fromJson(data), queryParameters: {'businessId': businessId});
  }
}
