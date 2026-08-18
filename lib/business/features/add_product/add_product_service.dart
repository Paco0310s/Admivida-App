import 'package:admivida/business/features/add_product/models/product_category_model.dart';
import 'package:admivida/business/features/add_product/models/product_type_model.dart';
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
}
