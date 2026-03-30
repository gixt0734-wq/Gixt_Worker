import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gixt_worker/Auth/Informacion.dart';
import 'package:gixt_worker/Auth/Login.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:gixt_worker/routes/root.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/theme_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// 🔔 LOCAL NOTIFICATIONS
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
/// 🔔 BACKGROUND HANDLER
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await dotenv.load(fileName: ".env");
  // await LocationService.initialize();
  /// 🔥 FIREBASE INIT
  await Firebase.initializeApp();

  /// 🔔 CONFIG FOREGROUND IOS (MUY IMPORTANTE)
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  /// 🔔 BACKGROUND
  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  /// 🔔 LOCAL NOTIFICATIONS INIT
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings =
      InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );

  

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Gixt',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          locale: const Locale('es', ''),
          home: const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void initState() {
    super.initState();

    // _subscription = Connectivity()
    //     .onConnectivityChanged
    //     .listen(_onConnectivityChange);

    _initFirebaseMessaging();

    _startAnimation();
  }

  /// 🔥 INIT FIREBASE NOTIFICATIONS
 Future<void> _initFirebaseMessaging() async {
  await _requestPermission();

  /// APP ABIERTA DESDE NOTIFICACION TERMINATED
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    if (initialMessage.data['serviceType'] == 'express') {
      Future.delayed(const Duration(seconds: 1), () {
       
      });
    }
  }

  /// FOREGROUND
  _listenForeground();
}

  // void _onConnectivityChange(List<ConnectivityResult> results) {
  //   if (results.contains(ConnectivityResult.none)) {
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (context) => SininternetPage()),
  //     );
  //   }
  // }

  Future<void> _requestPermission() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

 void _listenForeground() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {

    final notification = message.notification;
    final data = message.data;

 
final context = navigatorKey.currentContext;

    // if (context != null) {
    //   handleNotification(context, data, notification);
    // }

    /// Mostrar notificación local solo si hay contenido
    if (notification != null) {

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'canal',
        'Notificaciones',
        channelDescription: 'Notificaciones',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails =
          NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        notificationDetails,
      );
    }
  });
}

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      setState(() => _opacity = 1.0);
    }

    await Future.delayed(const Duration(seconds: 4));

    _checkUser();
  }

  Future<void> _checkUser() async {
    final prefs = await SharedPreferences.getInstance();

    String? inicio = prefs.getString('inicio');

    if (!mounted) return;

    if (inicio == 'true') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RootPage()),
      );
   
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  @override
  void dispose() {
     _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: AnimatedOpacity(
          duration: const Duration(seconds: 3),
          opacity: _opacity,
          child: Image.asset(
            'assets/logo.png',
            width: 250,
            height: 250,
            fit: BoxFit.contain,
            color:  colorsecundario,
          ),
        ),
      ),
    );
  }
}



