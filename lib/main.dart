import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/constants/app_theme.dart';
import 'package:admivida/common/logging/app_logger.dart';
import 'package:admivida/common/routes/app_routes.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/storage_service.dart';
import 'package:admivida/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize storage service
  await StorageService.init();

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
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
        localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        supportedLocales: const [Locale('es')],
        title: AppTexts.appName,
        theme: AppTheme.lightTheme,
        initialRoute: Routes.splash,
        routes: AppRoutes().routes,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
