// lib/main.dart
import 'dart:async';
//import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:medguard/api_service.dart';
import 'package:medguard/app_theme.dart';
import 'package:medguard/dashboard_screen.dart';
import 'package:medguard/l10n/app_localizations.dart';
import 'package:medguard/login_screen.dart';
import 'package:medguard/onboarding_screen.dart';
import 'package:medguard/providers/settings_provider.dart';
//import 'package:medicine_reminder_app/providers/locale_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; 
//import 'package:medicine_reminder_app/animated_splash_screen.dart';

/*@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final prefs = await SharedPreferences.getInstance();
  final bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  Widget initialScreen;
  if (!onboardingComplete) {
    initialScreen = const OnboardingScreen();
  } else {
    // Use the singleton instance directly
    final String? token = await ApiService.instance.getToken();
    initialScreen = (token != null) 
        ? const DashboardScreen() 
        : const LoginScreen();
  }

  runApp(
    ChangeNotifierProvider.value(
      // Use the singleton instance
      value: LocaleProvider.instance,
      child: MyApp(initialScreen: initialScreen),
    ),
  );
}*/

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

// NEW: A function to create our custom channel
Future<void> createNotificationChannel() async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const channel = AndroidNotificationChannel(
    'reminders_channel', // id
    'Medicine Reminders', // title
    description: 'Channel for medicine reminder notifications.', // description
    importance: Importance.max,
    playSound: true,
    // The name of your sound file from 'res/raw' WITHOUT the extension
    sound: RawResourceAndroidNotificationSound('reminder_sound'),
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await createNotificationChannel();

  final prefs = await SharedPreferences.getInstance();
  final bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  Widget initialScreen;
  if (!onboardingComplete) {
    initialScreen = const OnboardingScreen();
  } else {
    final String? token = await ApiService.instance.getToken();
    initialScreen = (token != null) 
        ? const DashboardScreen() 
        : const LoginScreen();
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => SettingsProvider(),
      child: MyApp(initialScreen: initialScreen),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;
  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      title: 'MedGuard',
      theme: AppTheme.theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsProvider.themeMode,
      locale: settingsProvider.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: initialScreen,
      debugShowCheckedModeBanner: false,
    );
  }
}

//27-09-2025/last
/*void main() async {
  // Use runZonedGuarded to catch all errors and send them to Crashlytics
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await createNotificationChannel();
    // --- NEW CRASHLYTICS SETUP ---
    // Pass all Flutter errors to Crashlytics
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    // Pass all non-Flutter errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    // --- END OF SETUP ---

    final prefs = await SharedPreferences.getInstance();
    final bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

    Widget initialScreen;
    if (!onboardingComplete) {
      initialScreen = const OnboardingScreen();
    } else {
      final String? token = await ApiService.instance.getToken();
      initialScreen = (token != null) 
          ? const DashboardScreen() 
          : const LoginScreen();
    }

    runApp(
      ChangeNotifierProvider(
        create: (context) => LocaleProvider.instance,
        //child: MyApp(initialScreen: initialScreen),
        child: const MyApp(),
      ),
    );
  }, (error, stack) => FirebaseCrashlytics.instance.recordError(error, stack, fatal: true));
}

class MyApp extends StatelessWidget {
  //final Widget initialScreen;
  //const MyApp({super.key, required this.initialScreen});
const MyApp({super.key}); 

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'MedGuard',
      theme: AppTheme.theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, 
      locale: localeProvider.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      //home: initialScreen,
      home: const AnimatedSplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}*/

/*// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:medicine_reminder_app/api_service.dart';
import 'package:medicine_reminder_app/app_theme.dart';
import 'package:medicine_reminder_app/dashboard_screen.dart';
import 'package:medicine_reminder_app/l10n/app_localizations.dart';
import 'package:medicine_reminder_app/login_screen.dart';
import 'package:medicine_reminder_app/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:medicine_reminder_app/providers/locale_provider.dart';
import 'package:provider/provider.dart';


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  final prefs = await SharedPreferences.getInstance();
  final bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
  
  // Check if the app was opened from a terminated state via a notification.
  final RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  final int? initialLogId = int.tryParse(initialMessage?.data['logId'] ?? '');

  Widget initialScreen;
  if (!onboardingComplete) {
    initialScreen = const OnboardingScreen();
  } else {
    final ApiService apiService = ApiService();
    final String? token = await apiService.getToken();
    initialScreen = (token != null) 
        ? DashboardScreen(initialLogId: initialLogId) // Pass the logId to the dashboard
        : const LoginScreen();
  }
 final GlobalKey<MyAppState> myAppKey = GlobalKey();
 // runApp(MyApp(initialScreen: initialScreen));
 runApp(
  ChangeNotifierProvider(
    create: (context) => LocaleProvider(),
    //child: MyApp(initialScreen: initialScreen),
     child: MyApp(key: myAppKey, initialScreen: initialScreen),
  ),
);
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;
  const MyApp({super.key, required this.initialScreen});

   @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    return MaterialApp(
      title: 'Medicine Reminder',
      //title: (AppLocalizations.of(context)!.appTitle),
      theme: AppTheme.theme,
      locale: localeProvider.locale,
       // --- ADD THESE LINES ---
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('hi'), // Hindi
        Locale('gu'), // Gujarati
      ],
      // --- END OF NEW LINES ---
      home: initialScreen,
      debugShowCheckedModeBanner: false,
    );
  }
}*/

/*// lib/main.dart
import 'package:flutter/material.dart';
import 'package:medicine_reminder_app/login_screen.dart';
import 'package:medicine_reminder_app/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';
import 'package:medicine_reminder_app/api_service.dart';
import 'package:medicine_reminder_app/dashboard_screen.dart';
import 'package:medicine_reminder_app/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

var logger = Logger();
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  logger.i("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  // Ensure everything is initialized
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // --- NEW, UPGRADED STARTUP LOGIC ---
  final prefs = await SharedPreferences.getInstance();
  final bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
 Widget initialScreen;
  if (!onboardingComplete) {
    initialScreen = const OnboardingScreen();
  } else {
    final ApiService apiService = ApiService();
    final String? token = await apiService.getToken();
    initialScreen = (token != null) ? const DashboardScreen() : const LoginScreen();
  }
  // --- END OF NEW LOGIC ---
  // --- NEW SESSION CHECK LOGIC ---
  /*final ApiService apiService = ApiService();
  final String? token = await apiService.getToken();
  // Decide which screen to show based on whether a token exists
  final Widget initialScreen = (token != null) 
      ? const DashboardScreen() 
      : const LoginScreen();
  // --- END OF NEW LOGIC ---
*/
  runApp(MyApp(initialScreen: initialScreen));
}
class MyApp extends StatelessWidget {
   final Widget initialScreen;
  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medicine Reminder',
      theme: AppTheme.theme,
       home: initialScreen,
      debugShowCheckedModeBanner: false,
    );
  }
}*/