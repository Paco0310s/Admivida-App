import 'package:admivida/common/features/sign_in/models/login_user_dto.dart';
import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/models/user_logged_model.dart';
import 'package:admivida/common/services/dio_service.dart';
import 'package:admivida/common/services/storage_service.dart';
import 'package:admivida/common/utils/either.dart';

class SignInService {
  static Future<bool> isSignedIn() async {
    final String? accessToken = StorageService.getString(AppConfig.accessTokenKey);
    final String? refreshToken = StorageService.getString(AppConfig.refreshTokenKey);
    return accessToken != null && refreshToken != null;
  }

  static Future<EitherUtil<HttpFailure, UserLoggedModel>> getUserData() async {
    return await DioService.get<UserLoggedModel>(
      AppConfig.profileEndpoint,
      (json) => UserLoggedModel.fromJson(json),
      queryParameters: {'refreshToken': StorageService.getString(AppConfig.refreshTokenKey)},
    );
  }

  static Future<EitherUtil<HttpFailure, UserLoggedModel>> signIn(LoginUserDto user) async {
    final Map<String, dynamic> data = {'emailOrPhone': user.emailOrPhone, 'password': user.password};
    return await DioService.post(AppConfig.loginEndpoint, data, (json) => UserLoggedModel.fromJson(json));
  }
}
