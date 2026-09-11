import 'package:admivida/business/features/commission_payments/models/business_staff_model.dart';
import 'package:admivida/business/features/commission_payments/models/pending_commission_item.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/services/dio_service.dart';
import 'package:admivida/common/utils/either.dart';
import 'package:admivida/common/constants/app_config.dart';

class CommissionPaymentsService {
  static Future<EitherUtil<HttpFailure, List<BusinessStaffModel>>> getSellers(String businessId) async {
    final response = await DioService.getList<BusinessStaffModel>(AppConfig.getBusinessSellersEndpoint(businessId), BusinessStaffModel.fromJson);

    return response.when((failure) => EitherUtil.failure(failure), (sellers) => EitherUtil.success(sellers));
  }

  /// Fetches the pending commission items for a specific seller.
  static Future<EitherUtil<HttpFailure, List<PendingCommissionItem>>> getPendingCommissions({required String businessId, required String sellerId}) async {
    final response = await DioService.getList<PendingCommissionItem>(
      AppConfig.getPendingCommissionsEndpoint(businessId),
      PendingCommissionItem.fromJson,
      queryParameters: {'sellerUserId': sellerId},
    );

    return response.when((failure) => EitherUtil.failure(failure), (items) => EitherUtil.success(items));
  }

  /// Submits the payment creation request to the backend.
  // static Future<EitherUtil<HttpFailure, void>> createPayment({required String businessId, required CreateCommissionPaymentDto dto}) async {
  //   final response = await DioService.post<void>(
  //     // Ensure you add this getter to your AppConfig: e.g., '/businesses/$businessId/commission-payments'
  //     AppConfig.createCommissionPaymentEndpoint(businessId),
  //     dto.toJson(),
  //     (_) {}, // Empty parser since we only care about the 201/200 status code
  //   );

  //   return response.when((failure) => EitherUtil.failure(failure), (_) => EitherUtil.success(null));
  // }
}
