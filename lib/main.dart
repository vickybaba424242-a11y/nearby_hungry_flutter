import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';

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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("📩 Background message: ${message.messageId}");
  debugPrint("📩 Background data: ${message.data}");
}

void handleNotificationClickFromData(Map<String, dynamic> data) {
  debugPrint("🔗 Notification click data: $data");

  if (data['target'] == 'chat') {
    final chefId = data['chefId'];
    final customerId = data['customerId'];
    final chefName = data['chefName'];

    if (chefId == null || customerId == null) {
      debugPrint("❌ Missing chefId or customerId in notification data: $data");
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushNamed(
        '/chat',
        arguments: {
          'chefId': chefId,
          'customerId': customerId,
          'chefName': chefName,
        },
      );
    });
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());

  _initNotificationsSafely();
}

Future<void> _initNotificationsSafely() async {
  try {
    await _initNotifications();
  } catch (e, st) {
    debugPrint("❌ Notification init failed: $e");
    debugPrintStack(stackTrace: st);
  }
}

Future<void> _initNotifications() async {
  final messaging = FirebaseMessaging.instance;

  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  debugPrint("🔔 Permission status: ${settings.authorizationStatus}");

  // Prevent duplicate foreground notifications on iOS.
  // We'll show our own local notification in onMessage.
  await messaging.setForegroundNotificationPresentationOptions(
    alert: false,
    badge: false,
    sound: false,
  );

  String? apnsToken;
  try {
    apnsToken = await messaging.getAPNSToken();
    int retry = 0;

    while (apnsToken == null && retry < 3) {
      await Future.delayed(const Duration(milliseconds: 800));
      apnsToken = await messaging.getAPNSToken();
      retry++;
    }

    debugPrint("🍎 APNS Token: $apnsToken");
  } catch (e, st) {
    debugPrint("❌ Failed to get APNS token: $e");
    debugPrintStack(stackTrace: st);
  }

  String? token;
  try {
    if (apnsToken != null) {
      token = await messaging.getToken();
      debugPrint("🔑 Device FCM Token: $token");
    } else {
      debugPrint("⚠️ APNS token not available yet, skipping FCM token fetch");
    }
  } catch (e, st) {
    debugPrint("❌ Failed to get FCM token: $e");
    debugPrintStack(stackTrace: st);
  }

  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initSettings = InitializationSettings(
    android: androidInit,
    iOS: iosInit,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (details) {
      debugPrint("🔔 Local notification tapped");
      debugPrint("🔔 Local notification payload: ${details.payload}");

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

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    debugPrint("📩 Foreground notification received");
    debugPrint("📩 Foreground messageId: ${message.messageId}");
    debugPrint("📩 Foreground title: ${message.notification?.title}");
    debugPrint("📩 Foreground body: ${message.notification?.body}");
    debugPrint("📩 Foreground data: ${message.data}");

    final notification = message.notification;
    if (notification == null) return;

    await flutterLocalNotificationsPlugin.show(
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
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint("📲 Notification opened app from background");
    debugPrint("📲 Opened message data: ${message.data}");
    handleNotificationClickFromData(message.data);
  });

  final RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    debugPrint("🚀 App opened from terminated state via notification");
    debugPrint("🚀 Initial message data: ${initialMessage.data}");
    handleNotificationClickFromData(initialMessage.data);
  }

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    debugPrint("♻️ FCM token refreshed: $newToken");
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
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const LoginPage(),
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
        '/register': (_) => const RegisterPage(),
        '/forgot_password': (_) => const ForgotPasswordPage(),
      },
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
    );
  }
}

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