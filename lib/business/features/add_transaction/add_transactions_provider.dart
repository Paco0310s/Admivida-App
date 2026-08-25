import 'package:admivida/business/features/add_transaction/add_transactions_service.dart';
import 'package:admivida/business/features/add_transaction/models/create_transaction_dto.dart';
import 'package:admivida/business/features/add_transaction/models/payment_method_model.dart';
import 'package:admivida/business/features/add_transaction/models/transaction_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'add_transactions_provider.g.dart';

@riverpod
Future<List<PaymentMethodModel>> paymentMethods(Ref ref) async {
  final result = await AddTransactionsService.getPaymentMethods();

  return result.when((failure) => throw failure, (methods) => methods);
}

@riverpod
class AddTransaction extends _$AddTransaction {
  @override
  FutureOr<TransactionModel?> build() {
    return null;
  }

  Future<void> submit(CreateTransactionDto dto) async {
    state = const AsyncValue.loading();

    final result = await AddTransactionsService.createTransaction(dto);

    state = result.when((failure) => AsyncValue.error(failure, StackTrace.current), (transaction) => AsyncValue.data(transaction));
  }
}
