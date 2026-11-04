import 'package:admivida/business/features/businesses/businesses_provider.dart';
import 'package:admivida/business/features/products/products_provider.dart';
import 'package:admivida/common/logging/app_logger.dart';
import 'package:admivida/common/models/user_logged_model.dart';
import 'package:flutter/material.dart';
import 'package:admivida/common/features/sign_in/sign_in_service.dart';
import 'package:admivida/common/constants/app_config.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/connectivity_service.dart';
import 'package:admivida/common/services/isar_cache_service.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/services/secure_storage_service.dart';
import 'package:admivida/common/services/windows_updater_service.dart';
import 'package:admivida/common/utils/either.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/windows_update_dialog.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'splash_provider.g.dart';

/// Entra a la app en modo offline (datos guardados en Isar) usando la sesión local.
void _enterOfflineMode(BuildContext context) {
  SnackbarUtil.showWarning(context, 'Modo Offline: Operando sin conexión a internet');

  final currentRole = SecureStorageService.getString(AppConfig.currentPlatformRoleKey);
  if (currentRole != null && currentRole.isNotEmpty) {
    NavigationService.replaceWith(context, Routes.home);
  } else {
    NavigationService.replaceWith(context, Routes.choosePlatformRole);
  }
}

bool _isSplashStartingUp = false;

@riverpod
Future<void> splashStartupLogic(Ref ref, BuildContext context) async {
  if (_isSplashStartingUp) return;
  _isSplashStartingUp = true;
  final keepAliveLink = ref.keepAlive();
  try {
    // 1. Check if the user is signed in and if there is physical internet connectivity FIRST
    final bool isSignedIn = await SignInService.isSignedIn();
    final hasInternet = await ConnectivityService.hasInternet();

    // 2. Without internet, we check if the user has a local session (OFFLINE MODE)
    if (!hasInternet) {
      if (isSignedIn) {
        // The user has a local session but no internet: they can continue and see the data cached in Isar
        if (context.mounted) _enterOfflineMode(context);
      } else {
        // The user has no internet and no local session: we cannot allow them to continue
        if (context.mounted) NavigationService.replaceWith(context, Routes.offline);
      }
      return;
    }

    // 3. WITH INTERNET: Ask the server for its public status (/health).
    //    - No response  -> server is down -> maintenance screen.
    //    - In maintenance flag -> maintenance screen (also for users who are not signed in).
    //    - App version below the minimum required -> update-required screen.
    final ServerStatus? serverStatus = await ConnectivityService.fetchServerStatus();
    if (serverStatus == null || serverStatus.inMaintenance) {
      if (context.mounted) {
        NavigationService.replaceWith(context, Routes.maintenance);
      }
      return;
    }

    if (serverStatus.requiresUpdate) {
      if (context.mounted) {
        NavigationService.replaceWith(context, Routes.updateRequired);
      }
      return;
    }

    // 3.1 WINDOWS: Revisar si hay un nuevo instalador publicado y ofrecer actualizar
    if (WindowsUpdaterService.isSupported) {
      final update = await WindowsUpdaterService.checkForUpdate();
      if (update != null && context.mounted) {
        await WindowsUpdateDialog.show(context, update);
      }
    }

    // 4. With internet and server live, but without a session: we redirect to the sign-in screen
    if (!isSignedIn) {
      if (context.mounted) NavigationService.replaceWith(context, Routes.signIn);
      return;
    }

    // 5. IDEAL SCENARIO: Validate the session (refresh token) and fetch user data
    final EitherUtil<HttpFailure, UserLoggedModel> userDataResponse = await SignInService.getUserData();

    await userDataResponse.when<Future<void>>(
      (failure) async {
        if (failure.statusCode == 401) {
          // Token vencido o sesión eliminada: limpiamos y mandamos al login.
          // Si el interceptor de Dio ya lo hizo (401 en /profile), el splash ya no está montado
          // y `context.mounted` es false, evitando doble navegación.
          await SecureStorageService.clear();
          await IsarCacheService.clearCache();
          if (context.mounted) {
            SnackbarUtil.showError(context, 'Tu sesión ha expirado, inicia sesión nuevamente.');
            NavigationService.replaceWith(context, Routes.signIn);
          }
          return;
        }

        // Fallo transitorio (sin red a mitad del arranque o servidor con error): la sesión sigue
        // siendo válida, por lo que NO se borra. Sin red -> modo offline; con red -> mantenimiento.
        if (!context.mounted) return;
        if (failure.type == 'CONNECTION_ERROR' && isSignedIn) {
          _enterOfflineMode(context);
        } else {
          NavigationService.replaceWith(context, Routes.maintenance);
        }
      },
      (userData) async {
        // If everything is fine, we store the tokens and roles in secure storage for future sessions
        await SecureStorageService.saveUserSession(userData);
        if (ref.mounted) {
          ref.invalidate(businessesListProvider);
          ref.invalidate(businessRolesProvider);
          ref.invalidate(isBusinessAdminProvider);
        }
        if (!context.mounted) return;

        // Finally, we navigate the user to the appropriate screen based on their roles
        if (userData.roles.length > 1) {
          SnackbarUtil.showSuccess(context, 'Bienvenido ${userData.user.firstName}');
          NavigationService.replaceWith(context, Routes.choosePlatformRole);
        } else if (userData.roles.length == 1) {
          await SecureStorageService.setString(AppConfig.currentPlatformRoleKey, userData.roles.first);
          if (!context.mounted) return;
          SnackbarUtil.showSuccess(context, 'Bienvenido ${userData.user.firstName}');
          NavigationService.replaceWith(context, Routes.home);
        } else {
          SnackbarUtil.showError(context, 'No tienes roles asignados, por favor contacta al administrador.');
          await SecureStorageService.clear();
          await IsarCacheService.clearCache();
          if (!context.mounted) return;
          NavigationService.replaceWith(context, Routes.signIn);
        }
      },
    );
  } catch (e, st) {
    // Red de seguridad: cualquier excepción inesperada no debe dejar al usuario atrapado en el splash.
    AppLogger.error('Error inesperado en el arranque (splash): $e', error: e, stackTrace: st);
    if (context.mounted) {
      NavigationService.replaceWith(context, Routes.signIn);
    }
  } finally {
    _isSplashStartingUp = false;
    keepAliveLink.close();
  }
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
