import 'package:admivida/business/features/add_sale/models/create_sale_dto.dart';
import 'package:admivida/business/features/products/models/product_model.dart';
import 'package:admivida/business/features/sales/models/sale_model.dart';
import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/services/dio_service.dart';
import 'package:admivida/common/utils/either.dart';

class AddSaleService {
  static Future<EitherUtil<HttpFailure, SaleModel>> createSale(CreateSaleDto dto) async {
    final response = await DioService.post<SaleModel>('/sales', dto.toJson(), (json) => SaleModel.fromJson(json));
    return response.when((failure) => EitherUtil.failure(failure), (saleModel) => EitherUtil.success(saleModel));
  }

  static Future<EitherUtil<HttpFailure, ProductsPageModel>> getTenantProducts(
    String businessId, {
    required int page,
    required int limit,
    String? nameOrSku,
  }) async {
    final Map<String, dynamic> queryParams = {'page': page, 'limit': limit, 'isActive': true, 'stockGreaterThan': 0};

    if (nameOrSku != null && nameOrSku.trim().isNotEmpty) {
      queryParams['search'] = nameOrSku.trim();
    }

    final response = await DioService.get<ProductsPageModel>(
      AppConfig.productsTenantEndpoint(businessId),
      (json) => ProductsPageModel.fromJson(json),
      queryParameters: queryParams,
    );

    return response.when((failure) => EitherUtil.failure(failure), (pageResponse) => EitherUtil.success(pageResponse));
  }
}
