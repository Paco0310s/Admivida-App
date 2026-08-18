import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/features/sign_up/models/create_user_dto.dart';
import 'package:admivida/common/models/user_logged_model.dart';
import 'package:admivida/common/services/dio_service.dart';
import 'package:admivida/common/utils/either.dart';

class SignUpService {
  static Future<EitherUtil<HttpFailure, UserLoggedModel>> signUp(CreateUserDto userCreateModel) async {
    return await DioService.post(AppConfig.registerEndpoint, userCreateModel.toJson(), (json) => UserLoggedModel.fromJson(json));
  }
}
