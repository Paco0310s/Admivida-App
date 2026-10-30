import 'dart:io';

import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/features/sign_in/models/login_user_dto.dart';
import 'package:admivida/common/logging/app_logger.dart';
import 'package:admivida/common/models/user_logged_model.dart';
import 'package:admivida/common/services/dio_service.dart';
import 'package:admivida/common/services/isar_cache_service.dart';
import 'package:admivida/common/services/secure_storage_service.dart';
import 'package:admivida/common/utils/either.dart';
import 'package:admivida/common/widgets/dashboard_navigation.dart';
import 'package:flutter/foundation.dart';

class SignInService {
  static String get currentAppVersion => 'v${AppConfig.appVersionName}+${AppConfig.appVersionCode}';

  static String? get currentDeviceInfo {
    if (kIsWeb) {
      // En Web devolvemos null para que el backend tome el header User-Agent completo del navegador
      return null;
    }
    try {
      return '${Platform.operatingSystem.toUpperCase()} (${Platform.operatingSystemVersion})';
    } catch (_) {
      return defaultTargetPlatform.name.toUpperCase();
    }
  }

  static Map<String, dynamic> buildDeviceSessionMeta({
    String? fcmToken,
    String? deviceInfo,
    String? appVersion,
  }) {
    final resolvedDeviceInfo = deviceInfo ?? currentDeviceInfo;
    final resolvedAppVersion = appVersion ?? currentAppVersion;

    return {
      if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
      if (resolvedDeviceInfo != null && resolvedDeviceInfo.isNotEmpty) 'deviceInfo': resolvedDeviceInfo,
      if (resolvedAppVersion.isNotEmpty) 'appVersion': resolvedAppVersion,
    };
  }

  static Future<bool> isSignedIn() async {
    final String? accessToken = SecureStorageService.getString(AppConfig.accessTokenKey);
    final String? refreshToken = SecureStorageService.getString(AppConfig.refreshTokenKey);
    return accessToken != null &&
        accessToken.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty;
  }

  static Future<EitherUtil<HttpFailure, UserLoggedModel>> getUserData() async {
    final newAccessToken = await DioService.refreshAccessToken();
    if (newAccessToken == null || newAccessToken.isEmpty) {
      return EitherUtil.failure(HttpFailure.serverError(401, 'La sesión ha caducado.'));
    }

    return DioService.get<UserLoggedModel>(
      AppConfig.profileEndpoint,
      (json) => UserLoggedModel.fromJson(json),
    );
  }

  static Future<EitherUtil<HttpFailure, UserLoggedModel>> signIn(LoginUserDto user) async {
    final Map<String, dynamic> data = {
      ...user.toJson(),
      ...buildDeviceSessionMeta(
        fcmToken: user.fcmToken,
        deviceInfo: user.deviceInfo,
        appVersion: user.appVersion,
      ),
    };
    return await DioService.post(AppConfig.loginEndpoint, data, (json) => UserLoggedModel.fromJson(json));
  }

  static Future<void> signOut() async {
    try {
      final refreshToken = SecureStorageService.getString(AppConfig.refreshTokenKey);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await DioService.post<Map<String, dynamic>>(
          AppConfig.logoutEndpoint,
          {'refreshToken': refreshToken},
          (json) => json,
        );
      }
    } catch (e) {
      AppLogger.warning('No se pudo notificar logout al servidor (limpiando sesión local): $e');
    } finally {
      DashboardSession.clear();
      await SecureStorageService.clear();
      await IsarCacheService.clearCache();
    }
  }
}
