import 'package:admivida/business/features/transactions/models/account_model.dart';
import 'package:admivida/business/features/transactions/models/paginated_transactions_model.dart';
import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/services/dio_service.dart';
import 'package:admivida/common/utils/either.dart';

class TransactionsService {
  static Future<EitherUtil<HttpFailure, PaginatedTransactionsResponse>> getTenantTransactions({
    required int page,
    required int limit,
    required String businessId,
    String? accountId,
  }) async {
    final Map<String, dynamic> queryParams = {
      'businessId': businessId,
      'page': page,
      'limit': limit,
      if (accountId != null && accountId.isNotEmpty) 'accountId': accountId,
    };

    final response = await DioService.get<PaginatedTransactionsResponse>(
      AppConfig.transactionsTenantEndpoint,
      (json) => PaginatedTransactionsResponse.fromJson(json),
      queryParameters: queryParams,
    );

    return response.when((failure) => EitherUtil.failure(failure), (pageResponse) => EitherUtil.success(pageResponse));
  }

  static Future<EitherUtil<HttpFailure, List<AccountModel>>> getAccountsBusiness({String? businessId}) async {
    final response = await DioService.getList<AccountModel>(AppConfig.accountsBusinessEndpoint(businessId), AccountModel.fromJson);

    return response.when((failure) => EitherUtil.failure(failure), (accounts) => EitherUtil.success(accounts));
  }
}
