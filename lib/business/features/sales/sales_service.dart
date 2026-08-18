import 'package:admivida/business/features/sales/models/sale_model.dart';
import 'package:admivida/business/features/sales/models/sales_page_model.dart';
import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/services/dio_service.dart';
import 'package:admivida/common/utils/either.dart';

class SalesService {
  static Future<EitherUtil<HttpFailure, SalesPageModel>> getTenantSales({required int page, required int limit, required String businessId}) async {
    final response = await DioService.get<SalesPageModel>(
      AppConfig.salesTenantEndpoint(businessId),
      (json) => SalesPageModel.fromJson(json),
      queryParameters: {'page': page, 'limit': limit},
    );

    return response.when((failure) => EitherUtil.failure(failure), (pageResponse) => EitherUtil.success(pageResponse));
  }

  static Future<EitherUtil<HttpFailure, SaleModel>> getSaleById({required String saleId, required String businessId}) async {
    final response = await DioService.get<SaleModel>('/sales/$saleId', (json) => SaleModel.fromJson(json), queryParameters: {'businessId': businessId});

    return response.when((failure) => EitherUtil.failure(failure), (sale) => EitherUtil.success(sale));
  }
}
