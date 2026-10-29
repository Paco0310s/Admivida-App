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

  static Future<EitherUtil<HttpFailure, PaginatedTransactionsResponse>> getPersonalTransactions({
    required int page,
    required int limit,
    String? accountId,
    String category = 'REAL',
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'limit': limit,
      'category': category,
      if (accountId != null && accountId.isNotEmpty) 'accountId': accountId,
    };

    final response = await DioService.get<PaginatedTransactionsResponse>(
      AppConfig.transactionsPersonalEndpoint,
      (json) => PaginatedTransactionsResponse.fromJson(json),
      queryParameters: queryParams,
    );

    return response.when((failure) => EitherUtil.failure(failure), (pageResponse) => EitherUtil.success(pageResponse));
  }

  static Future<EitherUtil<HttpFailure, List<AccountModel>>> getAccountsBusiness({String? businessId}) async {
    final response = await DioService.getList<AccountModel>(AppConfig.accountsBusinessEndpoint(businessId), AccountModel.fromJson);

    return response.when((failure) => EitherUtil.failure(failure), (accounts) => EitherUtil.success(accounts));
  }

  static Future<EitherUtil<HttpFailure, List<AccountModel>>> getPersonalAccounts() async {
    final response = await DioService.getList<AccountModel>(AppConfig.accountsPersonalEndpoint, AccountModel.fromJson);

    return response.when((failure) => EitherUtil.failure(failure), (accounts) => EitherUtil.success(accounts));
  }

  static Future<EitherUtil<HttpFailure, AccountModel>> createAccount({
    required String name,
    String accountTypeCode = 'CASH',
    String? description,
    String? businessId,
    double? creditLimit,
    double? initialBalance,
  }) async {
    final Map<String, dynamic> body = {
      'name': name.trim(),
      'accountTypeCode': accountTypeCode,
      if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
      if (businessId != null && businessId.trim().isNotEmpty) 'businessId': businessId.trim(),
      if (creditLimit != null && creditLimit > 0) 'creditLimit': creditLimit,
      if (initialBalance != null && initialBalance > 0) 'initialBalance': initialBalance,
    };

    final response = await DioService.post<AccountModel>(
      AppConfig.createAccountEndpoint,
      body,
      (json) => AccountModel.fromJson(json),
    );

    return response.when((failure) => EitherUtil.failure(failure), (account) => EitherUtil.success(account));
  }
}
