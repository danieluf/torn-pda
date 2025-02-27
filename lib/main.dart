// Dart imports:
import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;
// Package imports:
import 'package:bot_toast/bot_toast.dart';

// Useful for functions debugging
// ignore: unused_import
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dart_ping_ios/dart_ping_ios.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// Flutter imports:
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:torn_pda/firebase_options.dart';
import 'package:torn_pda/providers/api_caller.dart';
import 'package:torn_pda/utils/appwidget/pda_widget.dart';
import 'package:torn_pda/utils/http_overrides.dart';
import 'package:workmanager/workmanager.dart';
// Project imports:
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/providers/attacks_provider.dart';
import 'package:torn_pda/providers/awards_provider.dart';
import 'package:torn_pda/providers/chain_status_provider.dart';
import 'package:torn_pda/providers/crimes_provider.dart';
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/providers/quick_items_faction_provider.dart';
import 'package:torn_pda/providers/quick_items_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';
import 'package:torn_pda/providers/tac_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/terminal_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/trades_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/torn-pda-native/auth/native_auth_provider.dart';
import 'package:torn_pda/torn-pda-native/auth/native_user_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

// TODO: CONFIGURE FOR APP RELEASE, include exceptions in Drawer if applicable
const String appVersion = '3.1.4';
const String androidCompilation = '331';
const String iosCompilation = '331';

final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

final StreamController<ReceivedNotification> didReceiveLocalNotificationStream =
    StreamController<ReceivedNotification>.broadcast();

final StreamController<String> selectNotificationStream = StreamController<String>.broadcast();

class ReceivedNotification {
  ReceivedNotification({
    @required this.id,
    @required this.title,
    @required this.body,
    @required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final String payload;
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (message.data["channelId"].contains("Alerts stocks") == true) {
      // Reload isolate (as we are reading from background)
      await Prefs().reload();
      final oldData = await Prefs().getDataStockMarket();
      var newData = "";
      if (oldData.isNotEmpty) {
        newData = "$oldData\n${message.notification.body}";
      } else {
        newData = "$oldData${message.notification.body}";
      }
      Prefs().setDataStockMarket(newData);
    }
  } catch (e) {
    FirebaseCrashlytics.instance.log("PDA Crash at Messaging Background Handler");
    FirebaseCrashlytics.instance.recordError("PDA Error: $e", null);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Workmanager for app widget
  // [isInDebugMode] sends notifications each time a task is performed
  Workmanager().initialize(pdaWidget_backgroundUpdate, isInDebugMode: false);

  // Flutter Local Notifications
  if (Platform.isAndroid) {
    final AndroidFlutterLocalNotificationsPlugin androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation.requestPermission();
  }

  tz.initializeTimeZones();
  const initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  const initializationSettingsIOS = DarwinInitializationSettings();

  const initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
      final String payload = notificationResponse.payload;
      if (notificationResponse.payload != null) {
        log('Notification payload: $payload');
        selectNotificationStream.add(payload);
      }
    },
  );
  // END # Flutter Local Notifications

  // ## FIREBASE
  // Before any of the Firebase services can be used, FlutterFire needs to be initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (kDebugMode) {
    // ! ONLY FOR TESTING FUNCTIONS LOCALLY, COMMENT AFTERWARDS
    //FirebaseFunctions.instanceFor(region: 'us-east4').useFunctionsEmulator('localhost', 5001);
    // Only 'true' intended for debugging, otherwise leave in false
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  }
  // Pass all uncaught errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  // ! Consider disabling for public release - Enable in beta to get plugins' method channel errors in Crashlytics
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  // https://docs.flutter.dev/testing/errors#errors-not-caught-by-flutter
  /*
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return false;
  };
  */

  // Needs to register plugin for iOS
  if (Platform.isIOS) {
    DartPingIOS.register();
  }

  Get.put(ApiCallerController(), permanent: true);

  HttpOverrides.global = MyHttpOverrides();

  runApp(
    MultiProvider(
      providers: [
        // UserDetailsProvider has to go first to initialize the others!
        ChangeNotifierProvider<UserDetailsProvider>(create: (context) => UserDetailsProvider()),
        ChangeNotifierProvider<TargetsProvider>(create: (context) => TargetsProvider()),
        ChangeNotifierProxyProvider<UserDetailsProvider, AttacksProvider>(
          create: (context) => AttacksProvider(OwnProfileBasic()),
          update: (BuildContext context, UserDetailsProvider userProvider, AttacksProvider attacksProvider) =>
              AttacksProvider(userProvider.basic),
        ),
        ChangeNotifierProvider<ThemeProvider>(create: (context) => ThemeProvider()),
        ChangeNotifierProvider<SettingsProvider>(create: (context) => SettingsProvider()),
        ChangeNotifierProvider<FriendsProvider>(
          create: (context) => FriendsProvider(),
        ),
        ChangeNotifierProvider<UserScriptsProvider>(
          create: (context) => UserScriptsProvider(),
        ),
        ChangeNotifierProvider<ChainStatusProvider>(
          create: (context) => ChainStatusProvider(),
        ),
        ChangeNotifierProvider<CrimesProvider>(
          create: (context) => CrimesProvider(),
        ),
        ChangeNotifierProvider<QuickItemsProvider>(
          create: (context) => QuickItemsProvider(),
        ),
        ChangeNotifierProvider<QuickItemsProviderFaction>(
          create: (context) => QuickItemsProviderFaction(),
        ),
        ChangeNotifierProvider<TradesProvider>(
          create: (context) => TradesProvider(),
        ),
        ChangeNotifierProvider<ShortcutsProvider>(
          create: (context) => ShortcutsProvider(),
        ),
        ChangeNotifierProvider<AwardsProvider>(
          create: (context) => AwardsProvider(),
        ),
        ChangeNotifierProvider<TacProvider>(
          create: (context) => TacProvider(),
        ),
        ChangeNotifierProvider<TerminalProvider>(
          create: (context) => TerminalProvider(""),
        ),
        ChangeNotifierProvider<WebViewProvider>(
          create: (context) => WebViewProvider(),
        ),
        // Native login
        ChangeNotifierProvider<NativeAuthProvider>(create: (context) => NativeAuthProvider()),
        ChangeNotifierProvider<NativeUserProvider>(create: (context) => NativeUserProvider()),
        // ------------
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeProvider _themeProvider;
  WebViewProvider _webViewProvider;

  @override
  void initState() {
    super.initState();

    // Handle home widget
    if (Platform.isAndroid) {
      HomeWidget.setAppGroupId('torn_pda');
      HomeWidget.registerBackgroundCallback(pdaWidget_callback);
      pdaWidget_handleBackgroundUpdateStatus();
    }

    // Callback to force the browser back to full screen if there is a system request to revert
    // Might happen when app is on the background or when only the top is being extended
    SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
      if (_webViewProvider.currentUiMode == UiMode.fullScreen && systemOverlaysAreVisible) {
        _webViewProvider.setCurrentUiMode(UiMode.fullScreen, context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);

    ThemeData theme = ThemeData(
      cardColor: _themeProvider.cardColor,
      appBarTheme: AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        color: _themeProvider.statusBar,
      ),
      primarySwatch: Colors.blueGrey,
      brightness: _themeProvider.currentTheme == AppTheme.light ? Brightness.light : Brightness.dark,
    );

    MediaQuery mq = MediaQuery(
      data: MediaQueryData.fromWindow(ui.window),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MaterialApp(
          title: 'Torn PDA',
          theme: theme,
          debugShowCheckedModeBanner: false,
          builder: BotToastInit(),
          navigatorObservers: [BotToastNavigatorObserver()],
          home: WillPopScope(
            onWillPop: () async {
              WebViewProvider w = Provider.of<WebViewProvider>(context, listen: false);

              if (w.browserShowInForeground) {
                // Browser is in front, delegate the call
                w.tryGoBack();
                return false;
              } else {
                // App is in front
                //_webViewProvider.willPopCallbackStream.add(true);
                bool shouldPop = await _willPopFromApp();
                if (shouldPop) return true;
                return false;
              }
            },
            child: Stack(
              children: [
                GetMaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: theme,
                  home: DrawerPage(),
                ),
                Consumer<WebViewProvider>(
                  builder: (context, wProvider, child) {
                    return Visibility(
                      maintainState: true,
                      visible: wProvider.browserShowInForeground,
                      child: wProvider.stackView,
                    );
                  },
                ),
                const AppBorder(),
              ],
            ),
          ),
        ),
      ),
    );

    var orientation = mq.data.orientation;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: _themeProvider.statusBar,
        systemNavigationBarColor:
            orientation == Orientation.landscape ? _themeProvider.canvas : _themeProvider.statusBar,
        systemNavigationBarIconBrightness: orientation == Orientation.landscape
            ? _themeProvider.currentTheme == AppTheme.light
                ? Brightness.dark
                : Brightness.light
            : Brightness.light,
        statusBarBrightness: _themeProvider.currentTheme == AppTheme.light
            ? orientation == Orientation.portrait
                ? Brightness.dark
                : Brightness.light
            : Brightness.dark,
        statusBarIconBrightness: orientation == Orientation.portrait ? Brightness.light : Brightness.light,
      ),
    );

    return mq;
  }

  Future<bool> _willPopFromApp() async {
    SettingsProvider s = Provider.of<SettingsProvider>(context, listen: false);
    final appExit = s.onAppExit;
    if (appExit == 'exit') {
      return true;
    } else {
      if (routeWithDrawer) {
        // Open drawer instead
        s.willPopShouldOpenDrawer.add(true);
        return false;
      } else {
        s.willPopShouldGoBack.add(true);
        return false;
      }
    }
  }
}

class AppBorder extends StatefulWidget {
  const AppBorder({Key key}) : super(key: key);

  @override
  _AppBorderState createState() => _AppBorderState();
}

class _AppBorderState extends State<AppBorder> {
  @override
  Widget build(BuildContext context) {
    final _chainStatusProvider = Provider.of<ChainStatusProvider>(context, listen: true);
    return IgnorePointer(
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  width: _chainStatusProvider.watcherActive ? 3 : 0,
                  color: _chainStatusProvider.borderColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
