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
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'splash_provider.g.dart';

@riverpod
Future<void> splashStartupLogic(Ref ref, BuildContext context) async {
  // 1. Check if the user is signed in and if there is physical internet connectivity FIRST
  final bool isSignedIn = await SignInService.isSignedIn();
  final hasInternet = await ConnectivityService.hasInternet();

  // 2. Without internet, we check if the user has a local session (OFFLINE MODE)
  if (!hasInternet) {
    if (isSignedIn) {
      // The user has a local session but no internet: we can allow them to continue in offline mode
      if (context.mounted) {
        SnackbarUtil.showWarning(context, 'Modo Offline: Operando sin conexión a internet');

        // Check if the user has a current role stored in local storage
        final currentRole = StorageService.getString(AppConfig.currentPlatformRoleKey);
        if (currentRole != null && currentRole.isNotEmpty) {
          NavigationService.replaceWith(context, Routes.home);
        } else {
          NavigationService.replaceWith(context, Routes.choosePlatformRole);
        }
      }
    } else {
      // The user has no internet and no local session: we cannot allow them to continue
      if (context.mounted) NavigationService.replaceWith(context, Routes.offline);
    }
    return;
  }

  // 3. WITH INTERNET: Check if the server is live, if not we show a maintenance screen
  final bool serverLive = await ConnectivityService.isServerLive();
  if (!serverLive) {
    if (context.mounted) {
      NavigationService.replaceWith(context, Routes.maintenance);
    }
    return;
  }

  // 4. With internet and server live, but without a session: we redirect to the sign-in screen
  if (!isSignedIn) {
    if (context.mounted) NavigationService.replaceWith(context, Routes.signIn);
    return;
  }

  // 5. IDEAL SCENARIO: Fetch user data to validate versions and refresh tokens
  final EitherUtil<HttpFailure, UserLoggedModel> userDataResponse = await SignInService.getUserData();

  userDataResponse.when(
    (failure) {
      SnackbarUtil.showError(context, failure.message);
      if (context.mounted) NavigationService.replaceWith(context, Routes.signIn);
    },
    (userData) async {
      // Validate if the app version is below the minimum required version
      if (userData.minRequiredVersionCode > AppConfig.appVersionCode) {
        if (context.mounted) {
          NavigationService.replaceWith(context, Routes.updateRequired);
        }
        return;
      }

      // Validate internal maintenance flag for the user (just in case)
      if (userData.inMaintenance) {
        if (context.mounted) {
          NavigationService.replaceWith(context, Routes.maintenance);
        }
        return;
      }

      // If everything is fine, we store the tokens and roles in local storage for future sessions
      StorageService.setString(AppConfig.accessTokenKey, userData.accessToken);
      StorageService.setString(AppConfig.refreshTokenKey, userData.refreshToken);
      StorageService.setString(AppConfig.rolesKey, userData.roles.join(','));

      // Finally, we navigate the user to the appropriate screen based on their roles
      if (userData.roles.length > 1) {
        SnackbarUtil.showSuccess(context, 'Bienvenido ${userData.user.firstName}');
        NavigationService.replaceWith(context, Routes.choosePlatformRole);
      } else if (userData.roles.length == 1) {
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
