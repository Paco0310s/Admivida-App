import 'package:admivida/business/features/commission_payments/commission_payment_service.dart';
import 'package:admivida/business/features/commission_payments/models/business_staff_model.dart';
import 'package:admivida/business/features/commission_payments/models/pending_commission_item.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'commission_payment_provider.g.dart';

/// Provider to fetch the list of sellers/admins for the dropdown.
@riverpod
Future<List<BusinessStaffModel>> businessSellers(Ref ref, String businessId) async {
  final result = await CommissionPaymentsService.getSellers(businessId);

  return result.when((failure) => throw failure, (sellers) => sellers);
}

/// Provider to fetch the pending commissions.
/// It automatically invalidates/refetches if the businessId or sellerId changes.
@riverpod
Future<List<PendingCommissionItem>> pendingCommissions(Ref ref, {required String businessId, required String sellerId}) async {
  final result = await CommissionPaymentsService.getPendingCommissions(businessId: businessId, sellerId: sellerId);

  return result.when((failure) => throw failure, (items) => items);
}

/// Controller to handle the POST request state (Loading, Success, Error).
// @riverpod
// class CommissionPaymentController extends _$CommissionPaymentController {
//   @override
//   FutureOr<void> build() {}

//   /// Executes the payment creation and invalidates the pending list on success.
//   Future<bool> payCommissions({
//     required String businessId,
//     required String sellerUserId,
//     required List<String> saleDetailIds,
//     required double totalAmountPaid,
//   }) async {
//     state = const AsyncValue.loading();

//     final dto = CreateCommissionPaymentDto(
//       sellerUserId: sellerUserId,
//       saleDetailIds: saleDetailIds,
//       totalAmountPaid: totalAmountPaid,
//     );

//     final result = await CommissionPaymentsService.createPayment(
//       businessId: businessId,
//       dto: dto,
//     );

//     return result.when(
//       (failure) {
//         state = AsyncValue.error(failure, StackTrace.current);
//         return false;
//       },
//       (success) {
//         state = const AsyncValue.data(null);
        
//         // Refresh the pending list so the paid items disappear from the UI
//         ref.invalidate(pendingCommissionsProvider);
//         return true;
//       },
//     );
//   }
// }