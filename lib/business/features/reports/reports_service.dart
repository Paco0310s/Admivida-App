import 'package:admivida/business/features/reports/models/business_report_model.dart';
import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/services/dio_service.dart';
import 'package:admivida/common/utils/either.dart';

class ReportsService {
  static Future<EitherUtil<HttpFailure, BusinessReportModel>> getBusinessOverviewReport({
    required String businessId,
    String? startDate,
    String? endDate,
    int? tzOffset,
  }) async {
    final Map<String, dynamic> queryParams = {
      if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
      if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
      'tzOffset': ?tzOffset,
    };

    final response = await DioService.get<BusinessReportModel>(
      AppConfig.businessReportsEndpoint(businessId),
      (json) => BusinessReportModel.fromJson(json),
      queryParameters: queryParams,
    );

    return response.when(
      (failure) => EitherUtil.failure(failure),
      (report) => EitherUtil.success(report),
    );
  }
}
