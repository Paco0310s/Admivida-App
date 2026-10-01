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
    final refreshToken = StorageService.getString(AppConfig.refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) {
      return EitherUtil.failure(HttpFailure.serverError(401, 'La sesión ha caducado.'));
    }

    final refreshResponse = await DioService.post<_RefreshTokens>(
      AppConfig.refreshTokenEndpoint,
      {'refreshToken': refreshToken},
      _RefreshTokens.fromJson,
    );

    return await refreshResponse.when<Future<EitherUtil<HttpFailure, UserLoggedModel>>>(
      (failure) async => EitherUtil.failure(failure),
      (tokens) async {
        await StorageService.setString(AppConfig.accessTokenKey, tokens.accessToken);
        await StorageService.setString(AppConfig.refreshTokenKey, tokens.refreshToken);

        return DioService.get<UserLoggedModel>(
          AppConfig.profileEndpoint,
          (json) => UserLoggedModel.fromJson(json),
        );
      },
    );
  }

  static Future<EitherUtil<HttpFailure, UserLoggedModel>> signIn(LoginUserDto user) async {
    final Map<String, dynamic> data = {'emailOrPhone': user.emailOrPhone, 'password': user.password};
    return await DioService.post(AppConfig.loginEndpoint, data, (json) => UserLoggedModel.fromJson(json));
  }
}

class _RefreshTokens {
  final String accessToken;
  final String refreshToken;

  const _RefreshTokens({required this.accessToken, required this.refreshToken});

  factory _RefreshTokens.fromJson(Map<String, dynamic> json) => _RefreshTokens(
        accessToken: (json['accessToken'] ?? json['access_token']) as String? ?? '',
        refreshToken: (json['refreshToken'] ?? json['refresh_token']) as String? ?? '',
      );
}
