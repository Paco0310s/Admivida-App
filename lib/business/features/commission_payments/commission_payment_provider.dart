import 'package:admivida/business/features/commission_payments/commission_payment_service.dart';
import 'package:admivida/business/features/commission_payments/models/business_staff_model.dart';
import 'package:admivida/business/features/commission_payments/models/pending_commission_item.dart';
import 'package:admivida/business/features/transactions/models/account_model.dart';
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

@riverpod
Future<List<AccountModel>> accountsUser(Ref ref, {String? userId}) async {
  final result = await CommissionPaymentsService.getAccountsUser(userId: userId);

  return result.when((failure) => throw failure, (accounts) => accounts);
}
