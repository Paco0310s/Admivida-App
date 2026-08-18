import 'package:admivida/common/constants/app_texts.dart';

class HttpFailure {
  final String message;
  final int? statusCode;
  final String? type;

  const HttpFailure({required this.message, this.statusCode, this.type});

  factory HttpFailure.connectionError() {
    return const HttpFailure(message: AppTexts.connectionError, type: 'CONNECTION_ERROR');
  }

  factory HttpFailure.connectionTimeout() {
    return const HttpFailure(message: AppTexts.connectionTimeout, type: 'CONNECTION_TIMEOUT_ERROR');
  }

  factory HttpFailure.sendTimeout() {
    return const HttpFailure(message: AppTexts.sendTimeout, type: 'SEND_TIMEOUT_ERROR');
  }

  factory HttpFailure.receiveTimeout() {
    return const HttpFailure(message: AppTexts.receiveTimeout, type: 'RECEIVE_TIMEOUT_ERROR');
  }

  factory HttpFailure.serverError(int statusCode, String message) {
    return HttpFailure(message: message, statusCode: statusCode, type: 'SERVER_ERROR');
  }

  factory HttpFailure.unexpectedError(String message) {
    return HttpFailure(message: '${AppTexts.unexpectedError}: $message', type: 'UNEXPECTED_ERROR');
  }

  factory HttpFailure.cancelled(String cancelledError) {
    return HttpFailure(message: cancelledError, type: 'CANCELLED_ERROR');
  }

  @override
  String toString() {
    return 'HttpFailure(message: $message, statusCode: $statusCode, type: $type)';
  }
}
