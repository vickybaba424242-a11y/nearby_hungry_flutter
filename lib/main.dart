import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/register_page.dart';
import 'screens/forgot_password.dart';
import 'screens/chat_page.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Nearby Hungry notifications',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

// --------------------
// Notification click handler
// --------------------
void handleNotificationClickFromData(Map<String, dynamic> data) {
  if (data['target'] == 'chat') {
    final chefId = data['chefId'];
    final customerId = data['customerId'];
    final chefName = data['chefName'];

    if (chefId == null || customerId == null) return;

    navigatorKey.currentState?.pushNamed(
      '/chat',
      arguments: {
        'chefId': chefId,
        'customerId': customerId,
        'chefName': chefName,
      },
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Run UI immediately
  runApp(const MyApp());

  // Setup notifications AFTER UI
  _initNotifications();

  // Handle terminated state (app opened via notification) with slight delay
  final RemoteMessage? initialMessage =
  await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    Future.delayed(const Duration(milliseconds: 500), () {
      handleNotificationClickFromData(initialMessage.data);
    });
  }
}

// ----------------------------------------
// Notifications setup
// ----------------------------------------
Future<void> _initNotifications() async {
  await FirebaseMessaging.instance.requestPermission();

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (details) {
      if (details.payload != null && details.payload!.isNotEmpty) {
        final data = jsonDecode(details.payload!);
        handleNotificationClickFromData(Map<String, dynamic>.from(data));
      }
    },
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  });

  // Background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // When app is in background and tapped
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    handleNotificationClickFromData(message.data);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Nearby Hungry',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const AuthWrapper(),

      // Chat route
      onGenerateRoute: (settings) {
        if (settings.name == '/chat') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => ChatPage(
              chefId: args['chefId'],
              customerId: args['customerId'],
              chefName: args['chefName'],
            ),
          );
        }
        return null;
      },

      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/register': (context) => const RegisterPage(),
        '/forgot_password': (context) => const ForgotPasswordPage(),
      },
    );
  }
}

// --------------------
// Auth wrapper to show login/home
// --------------------
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomePage();
        }

        return const LoginPage();
      },
    );
  }
}