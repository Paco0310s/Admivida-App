import 'package:admivida/business/features/clients/models/client_debt_model.dart';
import 'package:admivida/business/features/clients/models/client_payment_response.dart';
import 'package:admivida/business/features/clients/models/create_client_dto_model.dart';
import 'package:admivida/common/models/user_logged_model.dart';
import 'package:admivida/common/services/dio_service.dart';
import 'package:admivida/common/utils/either.dart';

import '../../../common/errors/http_failure.dart';

class ClientsService {
  static Future<EitherUtil<HttpFailure, ClientDebtPageModel>> getClientsWithDebt({
    required int page,
    required int limit,
    required String businessId,
    String? search,
    bool onlyWithDebt = false,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (onlyWithDebt) {
      queryParams['onlyWithDebt'] = 'true';
    }

    final response = await DioService.get<ClientDebtPageModel>(
      '/users/$businessId/clients-with-debt',
      (json) => ClientDebtPageModel.fromJson(json),
      queryParameters: queryParams,
    );

    return response.when((failure) => EitherUtil.failure(failure), (pageResponse) => EitherUtil.success(pageResponse));
  }

  static Future<EitherUtil<HttpFailure, List<PendingSaleModel>>> getPendingSales({required String clientId, required String businessId}) async {
    final response = await DioService.getList<PendingSaleModel>(
      '/sales/$clientId/pending-sales',
      (json) => PendingSaleModel.fromJson(json),
      queryParameters: {'businessId': businessId},
    );

    return response.when((failure) => EitherUtil.failure(failure), (sales) => EitherUtil.success(sales));
  }

  static Future<EitherUtil<HttpFailure, ClientPaymentResponse>> processClientPayment({
    required String businessId,
    required String clientId,
    required Map<String, dynamic> payload,
  }) async {
    final response = await DioService.post('/transactions/$businessId/clients/$clientId/payments', payload, (json) => ClientPaymentResponse.fromJson(json));

    return response.when((failure) => EitherUtil.failure(failure), (data) => EitherUtil.success(data));
  }

  static Future<EitherUtil<HttpFailure, UserModel>> createClient(CreateClientDto dto, String businessId) async {
    return await DioService.post<UserModel>('/users/$businessId/clients', dto.toJson(), (data) {
      final clientMap = data['client'] is Map<String, dynamic> ? data['client'] as Map<String, dynamic> : data;
      return UserModel.fromJson(clientMap);
    });
  }

  static Future<EitherUtil<HttpFailure, UserModel>> updateClient({
    required String businessId,
    required String clientId,
    required Map<String, dynamic> payload,
  }) async {
    return await DioService.patch<UserModel>('/users/$businessId/clients/$clientId', payload, (data) {
      final clientMap = data['client'] is Map<String, dynamic> ? data['client'] as Map<String, dynamic> : data;
      return UserModel.fromJson(clientMap);
    });
  }
}
