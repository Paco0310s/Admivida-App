import 'package:admivida/business/features/commission_payments/models/business_staff_model.dart';
import 'package:admivida/business/features/commission_payments/models/commission_payment_response_model.dart';
import 'package:admivida/business/features/commission_payments/models/create_commission_payment_dto.dart';
import 'package:admivida/business/features/commission_payments/models/pending_commission_item.dart';
import 'package:admivida/business/features/transactions/models/account_model.dart';
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

  // Creates a new commission payment for a seller.
  static Future<EitherUtil<HttpFailure, CommissionPaymentResponseModel>> createCommissionPayment(CreateCommissionPaymentDto dto, String businessId) async {
    final response = await DioService.post<CommissionPaymentResponseModel>(
      AppConfig.createCommissionPaymentEndpoint(businessId),
      dto.toJson(),
      CommissionPaymentResponseModel.fromJson,
    );
    return response.when((failure) => EitherUtil.failure(failure), (commissionPayment) => EitherUtil.success(commissionPayment));
  }

  static Future<EitherUtil<HttpFailure, List<AccountModel>>> getAccountsUser({String? userId}) async {
    final response = await DioService.getList<AccountModel>(AppConfig.accountsUserEndpoint(userId), AccountModel.fromJson);

    return response.when((failure) => EitherUtil.failure(failure), (accounts) => EitherUtil.success(accounts));
  }
}
