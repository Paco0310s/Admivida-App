import 'package:admivida/business/features/sales/models/sale_model.dart';
import 'package:admivida/business/features/sales/models/sales_page_model.dart';
import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/services/dio_service.dart';
import 'package:admivida/common/utils/either.dart';

class SalesService {
  static Future<EitherUtil<HttpFailure, SalesPageModel>> getTenantSales({
    required int page,
    required int limit,
    required String businessId,
    String? search,
    String? status,
    String? clientUserId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
      if (clientUserId != null && clientUserId.trim().isNotEmpty) 'clientUserId': clientUserId.trim(),
      if (startDate != null) 'startDate': startDate.toUtc().toIso8601String(),
      if (endDate != null) 'endDate': endDate.toUtc().toIso8601String(),
    };

    final response = await DioService.get<SalesPageModel>(
      AppConfig.salesTenantEndpoint(businessId),
      (json) => SalesPageModel.fromJson(json),
      queryParameters: queryParams,
    );

    return response.when((failure) => EitherUtil.failure(failure), (pageResponse) => EitherUtil.success(pageResponse));
  }

  static Future<EitherUtil<HttpFailure, SaleModel>> getSaleById({required String saleId, required String businessId}) async {
    final response = await DioService.get<SaleModel>('/sales/$saleId', (json) => SaleModel.fromJson(json), queryParameters: {'businessId': businessId});

    return response.when((failure) => EitherUtil.failure(failure), (sale) => EitherUtil.success(sale));
  }
}
