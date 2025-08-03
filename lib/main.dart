import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 🔔 Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🔙 Background Message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize local notifications plugin
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _setupFCMListeners();
  }

  // 🔐 Request notification permission
  void _requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permission granted');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('🟡 Provisional permission granted');
    } else {
      print('❌ Permission denied');
    }
  }

  // 🔔 Show local notification when app in foreground
  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',       // Channel ID
            'High Importance Notifications', // Channel name
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
        ),
      );
    }
  }

  // 📩 Setup Firebase Cloud Messaging listeners
  void _setupFCMListeners() async {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📥 Foreground message: ${message.messageId}');
      _showLocalNotification(message);
    });

    // When app opened from background due to notification click
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 App opened via notification: ${message.messageId}');
      // TODO: Navigate to specific screen if needed
    });

    // When app launched from terminated state via notification
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('🚀 App launched from terminated state by notification: ${initialMessage.messageId}');
      // TODO: Navigate to specific screen if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blood Bank App',
      theme: ThemeData(primarySwatch: Colors.red),
      debugShowCheckedModeBanner: false,
      home: FirebaseAuth.instance.currentUser != null
          ? const HomeScreen()
          : const AuthScreen(),
    );
  }
}
