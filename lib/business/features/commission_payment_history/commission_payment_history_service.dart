import 'package:admivida/business/features/commission_payment_history/models/commission_payment_history_response_model.dart';
import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/services/dio_service.dart';
import 'package:admivida/common/utils/either.dart';

class CommissionPaymentHistoryService {
  static Future<EitherUtil<HttpFailure, CommissionPaymentHistoryResponseModel>> getHistory(String businessId, bool isAdmin) async {
    final response = await DioService.get<CommissionPaymentHistoryResponseModel>(
      isAdmin ? AppConfig.getCommissionPaymentHistoryBusinessEndpoint(businessId) : AppConfig.getCommissionPaymentMyHistoryEndpoint(businessId),
      (json) => CommissionPaymentHistoryResponseModel.fromJson(json),
    );

    return response.when((failure) => EitherUtil.failure(failure), (historyData) => EitherUtil.success(historyData));
  }
}
