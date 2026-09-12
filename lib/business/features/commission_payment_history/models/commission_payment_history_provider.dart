import 'package:admivida/business/features/commission_payment_history/commission_payment_history_service.dart';
import 'package:admivida/business/features/commission_payment_history/models/commission_payment_history_response_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
// Asegúrate de importar tus modelos y servicios reales:
// import '../models/commission_payment_history_response_model.dart';
// import '../services/commission_payments_history_service.dart';

part 'commission_payment_history_provider.g.dart';

@riverpod
class CommissionPaymentsController extends _$CommissionPaymentsController {
  @override
  FutureOr<CommissionPaymentHistoryResponseModel> build({required String businessId, required bool isAdmin}) async {
    // Automatically fetches the history when the provider is initialized
    return _fetchHistory(businessId: businessId, isAdmin: isAdmin);
  }

  /// Private helper to fetch data from the service
  Future<CommissionPaymentHistoryResponseModel> _fetchHistory({required String businessId, required bool isAdmin}) async {
    final result = await CommissionPaymentHistoryService.getHistory(businessId, isAdmin);

    return result.when((failure) => throw Exception(failure.message), (historyData) => historyData);
  }

  /// Public method to manually refresh or reload the history if needed
  Future<void> refreshHistory() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchHistory(businessId: businessId, isAdmin: isAdmin));
  }
}
