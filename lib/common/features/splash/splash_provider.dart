import 'package:admivida/common/models/user_logged_model.dart';
import 'package:flutter/material.dart';
import 'package:admivida/common/features/sign_in/sign_in_service.dart';
import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/connectivity_service.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/services/storage_service.dart';
import 'package:admivida/common/utils/either.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'splash_provider.g.dart';

@riverpod
Future<void> splashStartupLogic(Ref ref, BuildContext context) async {
  final hasInternet = await ConnectivityService.hasInternet();

  if (!hasInternet) {
    if (context.mounted) NavigationService.replaceWith(context, Routes.offline);
    return;
  }

  final bool isSignedIn = await SignInService.isSignedIn();

  if (!isSignedIn) {
    if (context.mounted) NavigationService.replaceWith(context, Routes.signIn);
    return;
  }

  final EitherUtil<HttpFailure, UserLoggedModel> userDataResponse = await SignInService.getUserData();

  userDataResponse.when(
    (failure) {
      SnackbarUtil.showError(context, failure.message);
      if (context.mounted) NavigationService.replaceWith(context, Routes.signIn);
    },
    (userData) async {
      StorageService.setString(AppConfig.accessTokenKey, userData.accessToken);
      StorageService.setString(AppConfig.refreshTokenKey, userData.refreshToken);
      StorageService.setString(AppConfig.rolesKey, userData.roles.join(','));

      if (userData.roles.length > 1) {
        // Navigate to the choose platform role screen
        SnackbarUtil.showSuccess(context, 'Bienvenido ${userData.user.firstName}');
        NavigationService.replaceWith(context, Routes.choosePlatformRole);
      } else if (userData.roles.length == 1) {
        // Navigate to the home screen
        StorageService.setString(AppConfig.currentPlatformRoleKey, userData.roles.first);
        SnackbarUtil.showSuccess(context, 'Bienvenido ${userData.user.firstName}');
        NavigationService.replaceWith(context, Routes.home);
      } else {
        SnackbarUtil.showError(context, 'No tienes roles asignados, por favor contacta al administrador.');
      }
    },
  );
}

@riverpod
class SplashLoading extends _$SplashLoading {
  @override
  bool build() {
    return false;
  }

  void setLoading(bool value) {
    state = value;
  }
}
