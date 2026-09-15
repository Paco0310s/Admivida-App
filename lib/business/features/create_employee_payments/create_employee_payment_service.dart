import 'package:admivida/business/features/create_employee_payments/models/create_employee_payment_dto.dart';
import 'package:admivida/business/features/create_employee_payments/models/employee_payment_response_model.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/services/dio_service.dart';
import 'package:admivida/common/utils/either.dart';
import 'package:admivida/common/constants/app_config.dart';

class CreateEmployeePaymentService {
  static Future<EitherUtil<HttpFailure, EmployeePaymentResponseModel>> createEmployeePayment(CreateEmployeePaymentDto dto, String businessId) async {
    final response = await DioService.post<EmployeePaymentResponseModel>(
      AppConfig.createEmployeePaymentEndpoint(businessId),
      dto.toJson(),
      EmployeePaymentResponseModel.fromJson,
    );
    return response.when((failure) => EitherUtil.failure(failure), (employeePayment) => EitherUtil.success(employeePayment));
  }
}
