import 'package:admivida/business/features/businesses/businesses_provider.dart';
import 'package:admivida/business/features/products/products_provider.dart';
import 'package:admivida/common/models/user_logged_model.dart';
import 'package:flutter/material.dart';
import 'package:admivida/common/features/sign_up/sign_up_service.dart';
import 'package:admivida/common/features/sign_up/models/create_user_dto.dart';
import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/isar_cache_service.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/services/secure_storage_service.dart';
import 'package:admivida/common/utils/either.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sign_up_provider.g.dart';

@riverpod
Future<void> signUp(Ref ref, BuildContext context, CreateUserDto userCreateModel) async {
  final keepAliveLink = ref.keepAlive();
  try {
    final EitherUtil<HttpFailure, UserLoggedModel> userDataResponse = await SignUpService.signUp(userCreateModel);

    await userDataResponse.when<Future<void>>(
      (failure) async {
        if (context.mounted) {
          SnackbarUtil.showError(context, failure.message);
        }
      },
      (userData) async {
        if (userData.minRequiredVersionCode > AppConfig.appVersionCode) {
          if (context.mounted) {
            NavigationService.replaceWith(context, Routes.updateRequired);
          }
          return;
        }

        if (userData.inMaintenance) {
          if (context.mounted) {
            NavigationService.replaceWith(context, Routes.maintenance);
          }
          return;
        }

        await IsarCacheService.clearCache();
        await SecureStorageService.saveUserSession(userData);
        if (ref.mounted) {
          ref.invalidate(businessesListProvider);
          ref.invalidate(businessRolesProvider);
          ref.invalidate(isBusinessAdminProvider);
        }
        if (!context.mounted) return;

        if (userData.roles.length > 1) {
          // Navigate to the choose platform role screen
          SnackbarUtil.showSuccess(context, 'Bienvenido ${userData.user.firstName}');
          NavigationService.replaceWith(context, Routes.choosePlatformRole);
        } else if (userData.roles.length == 1) {
          // Navigate to the home screen
          await SecureStorageService.setString(AppConfig.currentPlatformRoleKey, userData.roles.first);
          if (!context.mounted) return;
          SnackbarUtil.showSuccess(context, 'Bienvenido ${userData.user.firstName}');
          NavigationService.replaceUntil(context, Routes.home);
        } else {
          SnackbarUtil.showError(context, 'No tienes roles asignados, por favor contacta al administrador.');
        }
      },
    );
  } finally {
    keepAliveLink.close();
  }
}

@riverpod
class SignUpLoading extends _$SignUpLoading {
  @override
  bool build() {
    return false; // Initial loading state is false
  }

  void setLoading(bool value) {
    state = value;
  }
}

@riverpod
Future<void> signUpWithGoogle(Ref ref, BuildContext context) async {
  SnackbarUtil.showInfo(context, AppTexts.isNotImplemented);
}

@riverpod
Future<void> signUpWithApple(Ref ref, BuildContext context) async {
  SnackbarUtil.showInfo(context, AppTexts.isNotImplemented);
}

@riverpod
Future<void> goToSignIn(Ref ref, BuildContext context) async {
  NavigationService.replaceUntil(context, Routes.signIn);
}

void showUpdateRequiredDialog(BuildContext context, String title, String content, String textButton) {
  if (context.mounted) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: Text(textButton),
              onPressed: () {
                SystemNavigator.pop();
              },
            ),
          ],
        );
      },
    );
  }
}
