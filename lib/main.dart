import 'dart:async';

import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/constants/app_theme.dart';
import 'package:admivida/common/logging/app_logger.dart';
import 'package:admivida/common/routes/app_routes.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/isar_cache_service.dart';
import 'package:admivida/common/services/secure_storage_service.dart';
import 'package:admivida/common/services/storage_service.dart';
import 'package:admivida/common/services/whats_new_service.dart';
import 'package:admivida/common/services/windows_updater_service.dart';
import 'package:admivida/common/utils/globals.dart';
import 'package:admivida/common/widgets/windows_update_dialog.dart';
import 'package:admivida/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize storage & cache services
  await StorageService.init();
  await SecureStorageService.init();
  await IsarCacheService.init();
  WhatsNewService.init();

  // Initialize Logger
  AppLogger.initialize();
  AppLogger.info("🚀 Admivida App Starting...");

  runApp(ProviderScope(child: AdmividaApp()));
}

class AdmividaApp extends ConsumerStatefulWidget {
  const AdmividaApp({super.key});

  @override
  ConsumerState<AdmividaApp> createState() => _AdmividaAppState();
}

class _AdmividaAppState extends ConsumerState<AdmividaApp> with WidgetsBindingObserver {
  Timer? _updateCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Windows: revisar periódicamente si hay una nueva versión mientras la app sigue abierta
    if (WindowsUpdaterService.isSupported) {
      _updateCheckTimer = Timer.periodic(const Duration(hours: 3), (_) => _checkForWindowsUpdate());
    }
  }

  Future<void> _checkForWindowsUpdate() async {
    final update = await WindowsUpdaterService.checkForUpdate();
    final dialogContext = navigatorKey.currentState?.overlay?.context;
    if (update == null || dialogContext == null || !dialogContext.mounted) return;
    await WindowsUpdateDialog.show(dialogContext, update);
  }

  @override
  void dispose() {
    _updateCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  // ignore: unnecessary_overrides
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: MaterialApp(
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,
        localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        supportedLocales: const [Locale('es')],
        title: AppTexts.appName,
        theme: AppTheme.lightTheme,
        initialRoute: Routes.splash,
        onGenerateRoute: AppRoutes().onGenerateRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
