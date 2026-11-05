import 'package:admivida/business/features/cash_shifts/models/cash_shift_model.dart';
import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/services/dio_service.dart';
import 'package:admivida/common/utils/either.dart';

class CashShiftsService {
  static Future<EitherUtil<HttpFailure, CashShiftModel?>> getActiveShift(
    String businessId,
  ) async {
    final response = await DioService.get<ActiveCashShiftResponse>(
      AppConfig.activeCashShiftEndpoint(businessId),
      ActiveCashShiftResponse.fromJson,
    );

    return response.when(
      (failure) => EitherUtil.failure(failure),
      (result) => EitherUtil.success(result.shift),
    );
  }

  static Future<EitherUtil<HttpFailure, CashShiftModel>> openShift({
    required String businessId,
    required double openingAmount,
    String? accountId,
    String? notes,
  }) async {
    return DioService.post<CashShiftModel>(
      AppConfig.openCashShiftEndpoint,
      {
        'businessId': businessId,
        'openingAmount': openingAmount,
        if (accountId != null && accountId.trim().isNotEmpty)
          'accountId': accountId.trim(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
      CashShiftModel.fromJson,
    );
  }

  static Future<EitherUtil<HttpFailure, CashShiftModel>> addMovement({
    required String shiftId,
    required String type, // 'IN' | 'OUT'
    required double amount,
    required String concept,
  }) async {
    return DioService.post<CashShiftModel>(
      AppConfig.addCashMovementEndpoint(shiftId),
      {
        'type': type,
        'amount': amount,
        'concept': concept.trim(),
      },
      CashShiftModel.fromJson,
    );
  }

  static Future<EitherUtil<HttpFailure, CashShiftModel>> closeShift({
    required String shiftId,
    required double actualCash,
    String? notes,
  }) async {
    return DioService.post<CashShiftModel>(
      AppConfig.closeCashShiftEndpoint(shiftId),
      {
        'actualCash': actualCash,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
      CashShiftModel.fromJson,
    );
  }

  static Future<EitherUtil<HttpFailure, PaginatedCashShiftsModel>> getBusinessShifts({
    required String businessId,
    int page = 1,
    int limit = 20,
  }) async {
    return DioService.get<PaginatedCashShiftsModel>(
      AppConfig.businessCashShiftsEndpoint(businessId),
      PaginatedCashShiftsModel.fromJson,
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
  }

  static Future<EitherUtil<HttpFailure, CashShiftModel>> getShiftDetail(
    String shiftId,
  ) async {
    return DioService.get<CashShiftModel>(
      AppConfig.cashShiftDetailEndpoint(shiftId),
      CashShiftModel.fromJson,
    );
  }
}

