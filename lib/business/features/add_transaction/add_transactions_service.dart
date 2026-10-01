import 'package:admivida/business/features/add_transaction/models/create_transaction_dto.dart';
import 'package:admivida/business/features/add_transaction/models/payment_method_model.dart';
import 'package:admivida/business/features/add_transaction/models/transaction_model.dart';
import 'package:admivida/business/features/add_transaction/models/transfer_funds_dto.dart';
import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/services/dio_service.dart';
import 'package:admivida/common/utils/either.dart';

class AddTransactionsService {
  static Future<EitherUtil<HttpFailure, List<PaymentMethodModel>>> getPaymentMethods() async {
    final response = await DioService.getList<PaymentMethodModel>(AppConfig.paymentMethodsEndpoint, PaymentMethodModel.fromJson);

    return response.when((failure) => EitherUtil.failure(failure), (methods) => EitherUtil.success(methods));
  }

  static Future<EitherUtil<HttpFailure, TransactionModel>> createTransaction(CreateTransactionDto dto) async {
    final response = await DioService.post<TransactionModel>(AppConfig.transactionsEndpoint, dto.toJson(), (json) => TransactionModel.fromJson(json));

    return response.when((failure) => EitherUtil.failure(failure), (transaction) => EitherUtil.success(transaction));
  }

  static Future<EitherUtil<HttpFailure, bool>> transferFunds(TransferFundsDto dto) async {
    final response = await DioService.post<dynamic>(AppConfig.transfersEndpoint, dto.toJson(), (json) => true);

    return response.when((failure) => EitherUtil.failure(failure), (success) => EitherUtil.success(true));
  }
}
