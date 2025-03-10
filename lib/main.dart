import 'dart:async';

import 'package:ardrive/authentication/ardrive_auth.dart';
import 'package:ardrive/blocs/activity/activity_cubit.dart';
import 'package:ardrive/blocs/feedback_survey/feedback_survey_cubit.dart';
import 'package:ardrive/blocs/upload/limits.dart';
import 'package:ardrive/blocs/upload/upload_file_checker.dart';
import 'package:ardrive/components/keyboard_handler.dart';
import 'package:ardrive/core/crypto/crypto.dart';
import 'package:ardrive/models/database/database_helpers.dart';
import 'package:ardrive/pst/ardrive_contract_oracle.dart';
import 'package:ardrive/pst/community_oracle.dart';
import 'package:ardrive/pst/contract_oracle.dart';
import 'package:ardrive/pst/contract_readers/redstone_contract_reader.dart';
import 'package:ardrive/pst/contract_readers/smartweave_contract_reader.dart';
import 'package:ardrive/pst/contract_readers/verto_contract_reader.dart';
import 'package:ardrive/services/authentication/biometric_authentication.dart';
import 'package:ardrive/services/config/config_fetcher.dart';
import 'package:ardrive/services/turbo/payment_service.dart';
import 'package:ardrive/theme/theme_switcher_bloc.dart';
import 'package:ardrive/theme/theme_switcher_state.dart';
import 'package:ardrive/user/repositories/user_preferences_repository.dart';
import 'package:ardrive/user/repositories/user_repository.dart';
import 'package:ardrive/utils/app_flavors.dart';
import 'package:ardrive/utils/html/html_util.dart';
import 'package:ardrive/utils/local_key_value_store.dart';
import 'package:ardrive/utils/logger/logger.dart';
import 'package:ardrive/utils/pre_cache_assets.dart';
import 'package:ardrive/utils/secure_key_value_store.dart';
import 'package:ardrive_http/ardrive_http.dart';
import 'package:ardrive_io/ardrive_io.dart';
import 'package:ardrive_ui/ardrive_ui.dart';
import 'package:arweave/arweave.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'blocs/blocs.dart';
import 'firebase_options.dart';
import 'models/models.dart';
import 'pages/pages.dart';
import 'services/services.dart';
import 'theme/theme.dart';

final overlayKey = GlobalKey<OverlayState>();

late ConfigService configService;
late ArweaveService _arweave;
late UploadService _turboUpload;
late PaymentService _turboPayment;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localStore = await LocalKeyValueStore.getInstance();

  configService = ConfigService(
    appFlavors: AppFlavors(EnvFetcher()),
    configFetcher: ConfigFetcher(localStore: localStore),
  );

  await configService.loadConfig();

  if (!kIsWeb) {
    final flavor = await configService.loadAppFlavor();

    if (flavor == Flavor.development) {
      _runWithCrashlytics(flavor.name);
      return;
    }
  }

  debugPrint('Starting without crashlytics');

  _runWithoutCrashlytics();
}

Future<void> _runWithoutCrashlytics() async {
  await _initialize();
  runApp(const App());
}

Future<void> _initialize() async {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
  );

  final config = configService.config;

  logger.d('Initializing with config: $config');

  ArDriveDownloader.initialize();

  _arweave = ArweaveService(
    Arweave(
      gatewayUrl: Uri.parse(config.defaultArweaveGatewayUrl!),
    ),
    ArDriveCrypto(),
  );
  _turboUpload = config.useTurboUpload
      ? UploadService(
          turboUploadUri: Uri.parse(config.defaultTurboUploadUrl!),
          allowedDataItemSize: config.allowedDataItemSizeForTurbo!,
          httpClient: ArDriveHTTP(),
        )
      : DontUseUploadService();

  _turboPayment = config.useTurboPayment
      ? PaymentService(
          turboPaymentUri: Uri.parse(config.defaultTurboPaymentUrl!),
          httpClient: ArDriveHTTP(),
        )
      : DontUsePaymentService();

  if (kIsWeb) {
    refreshHTMLPageAtInterval(const Duration(hours: 12));
  }
}

Future<void> _runWithCrashlytics(String flavor) async {
  runZonedGuarded<Future<void>>(
    () async {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await _initialize();

      FirebaseCrashlytics.instance
          .log('Starting application with crashlytics for $flavor');

      // Pass all uncaught errors from the framework to Crashlytics.
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      runApp(const App());
    },
    (error, stack) => FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      fatal: true,
    ),
  );
}

void refreshHTMLPageAtInterval(Duration duration) {
  Timer.periodic(duration, (timer) => triggerHTMLPageReload());
}

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  final AppRouterDelegate _routerDelegate = AppRouterDelegate();
  final _routeInformationParser = AppRouteInformationParser();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      preCacheLoginAssets(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ArweaveService>(create: (_) => _arweave),
        // repository provider for UploadFileChecker
        RepositoryProvider<UploadFileChecker>(
          create: (_) => UploadFileChecker(
            privateFileSafeSizeLimit:
                kIsWeb ? privateFileSizeLimit : mobilePrivateFileSizeLimit,
            publicFileSafeSizeLimit: publicFileSafeSizeLimit,
          ),
        ),
        RepositoryProvider<ArweaveService>(create: (_) => _arweave),
        RepositoryProvider<ConfigService>(
          create: (_) => configService,
        ),
        RepositoryProvider<UploadService>(
          create: (_) => _turboUpload,
        ),
        RepositoryProvider<PaymentService>(
          create: (_) => _turboPayment,
        ),
        RepositoryProvider<PstService>(
          create: (_) => PstService(
            communityOracle: CommunityOracle(
              ArDriveContractOracle([
                ContractOracle(VertoContractReader()),
                ContractOracle(RedstoneContractReader()),
                ContractOracle(SmartweaveContractReader()),
              ]),
            ),
          ),
        ),
        RepositoryProvider<BiometricAuthentication>(
          create: (_) => BiometricAuthentication(
            LocalAuthentication(),
            SecureKeyValueStore(
              const FlutterSecureStorage(),
            ),
          ),
        ),
        RepositoryProvider<Database>(create: (_) => Database()),
        RepositoryProvider<ProfileDao>(
            create: (context) => context.read<Database>().profileDao),
        RepositoryProvider<DriveDao>(
            create: (context) => context.read<Database>().driveDao),
        RepositoryProvider<UserRepository>(
          create: (context) => UserRepository(
            context.read<ProfileDao>(),
            context.read<ArweaveService>(),
          ),
        ),
        RepositoryProvider(
          create: (context) => ArDriveAuth(
            databaseHelpers: DatabaseHelpers(
              context.read<Database>(),
            ),
            arConnectService: ArConnectService(),
            biometricAuthentication: context.read<BiometricAuthentication>(),
            secureKeyValueStore: SecureKeyValueStore(
              const FlutterSecureStorage(),
            ),
            crypto: ArDriveCrypto(),
            arweave: _arweave,
            userRepository: context.read<UserRepository>(),
          ),
        ),
        RepositoryProvider(
          create: (_) => UserPreferencesRepository(
            themeDetector: ThemeDetector(),
          ),
        ),
      ],
      child: ArDriveDevToolsShortcuts(
        child: KeyboardHandler(
          child: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => ThemeSwitcherBloc(
                  userPreferencesRepository:
                      context.read<UserPreferencesRepository>(),
                )..add(LoadTheme()),
              ),
              BlocProvider(
                create: (context) => ProfileCubit(
                  arweave: context.read<ArweaveService>(),
                  turboUploadService: context.read<UploadService>(),
                  profileDao: context.read<ProfileDao>(),
                  db: context.read<Database>(),
                ),
              ),
              BlocProvider(
                create: (context) => ActivityCubit(),
              ),
              BlocProvider(
                create: (context) =>
                    FeedbackSurveyCubit(FeedbackSurveyInitialState()),
              ),
            ],
            child: BlocConsumer<ThemeSwitcherBloc, ThemeSwitcherState>(
              listener: (context, state) {
                if (state is ThemeSwitcherDarkTheme) {
                  ArDriveUIThemeSwitcher.changeTheme(ArDriveThemes.dark);
                } else if (state is ThemeSwitcherLightTheme) {
                  ArDriveUIThemeSwitcher.changeTheme(ArDriveThemes.light);
                }
              },
              builder: (context, state) {
                return ArDriveApp(
                  onThemeChanged: (theme) {
                    context.read<ThemeSwitcherBloc>().add(ChangeTheme());
                  },
                  key: arDriveAppKey,
                  builder: (context) => MaterialApp.router(
                    title: 'ArDrive',
                    theme: ArDriveTheme.of(context)
                        .themeData
                        .materialThemeData
                        .copyWith(
                          scaffoldBackgroundColor: ArDriveTheme.of(context)
                              .themeData
                              .backgroundColor,
                        ),
                    debugShowCheckedModeBanner: false,
                    routeInformationParser: _routeInformationParser,
                    routerDelegate: _routerDelegate,
                    localizationsDelegates: const [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                    ],
                    supportedLocales: const [
                      Locale('en', ''), // English, no country code
                      Locale('es', ''), // Spanish, no country code
                      Locale.fromSubtags(
                          languageCode: 'zh'), // generic Chinese 'zh'
                      Locale.fromSubtags(
                        languageCode: 'zh',
                        countryCode: 'HK',
                      ), // Traditional Chinese, Cantonese
                      Locale('ja', ''), // Japanese, no country code
                      Locale('hi', ''), // Hindi, no country code
                    ],
                    builder: (context, child) => ListTileTheme(
                      textColor: kOnSurfaceBodyTextColor,
                      iconColor: kOnSurfaceBodyTextColor,
                      child: Portal(
                        child: child!,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
