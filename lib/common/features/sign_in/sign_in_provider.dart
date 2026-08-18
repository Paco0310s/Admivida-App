import 'package:admivida/common/models/user_logged_model.dart';
import 'package:flutter/material.dart';
import 'package:admivida/common/features/sign_in/sign_in_service.dart';
import 'package:admivida/common/features/sign_in/models/login_user_dto.dart';
import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/services/storage_service.dart';
import 'package:admivida/common/utils/either.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sign_in_provider.g.dart';

@riverpod
Future<void> signIn(Ref ref, BuildContext context, LoginUserDto userLoginDto) async {
  final EitherUtil<HttpFailure, UserLoggedModel> userDataResponse = await SignInService.signIn(userLoginDto);

  userDataResponse.when(
    (failure) {
      SnackbarUtil.showError(context, failure.message);
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
class SignInLoading extends _$SignInLoading {
  @override
  bool build() {
    return false; // Initial loading state is false
  }

  void setLoading(bool value) {
    state = value;
  }
}

@riverpod
Future<void> signInWithGoogle(Ref ref, BuildContext context) async {
  SnackbarUtil.showInfo(context, AppTexts.isNotImplemented);
}

@riverpod
Future<void> signInWithApple(Ref ref, BuildContext context) async {
  SnackbarUtil.showInfo(context, AppTexts.isNotImplemented);
}

@riverpod
Future<void> goToSignUp(Ref ref, BuildContext context) async {
  NavigationService.navigateTo(context, Routes.signUp);
}

@riverpod
Future<void> goToForgotPassword(Ref ref, BuildContext context) async {
  NavigationService.navigateTo(context, Routes.forgotPassword);
}

@riverpod
class RememberMe extends _$RememberMe {
  @override
  bool build() {
    return false; // Default value for "Remember Me" is false
  }

  void toggle() {
    state = !state; // Toggle the boolean value
  }
}
