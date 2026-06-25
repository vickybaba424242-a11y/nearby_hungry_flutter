import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/register_page.dart';
import 'screens/forgot_password.dart';
import 'screens/chat_page.dart';
import 'active_chat.dart';

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

    if (chefId == null || customerId == null) return;

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

  await _initNotifications();

  runApp(const MyApp());
}

Future<void> _initNotifications() async {
  final messaging = FirebaseMessaging.instance;

  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  debugPrint("🔔 Permission status: ${settings.authorizationStatus}");

  await messaging.setForegroundNotificationPresentationOptions(
    alert: false,
    badge: true,
    sound: true,
  );

  try {
    String? token = await messaging.getToken();
    debugPrint("🔑 Device FCM Token: $token");

    final user = FirebaseAuth.instance.currentUser;

    if (user != null && token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint("♻️ FCM token refreshed: $newToken");

      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'fcmToken': newToken}, SetOptions(merge: true));
      }
    });
  } catch (e) {
    debugPrint("❌ Failed to get FCM token: $e");
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
      debugPrint("🔔 Notification tapped");

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
    final chefId = message.data['chefId'];
    final customerId = message.data['customerId'];

    if (chefId != null && customerId != null) {

      final incomingChatId =
      chefId.compareTo(customerId) < 0
          ? '${chefId}_$customerId'
          : '${customerId}_$chefId';

      if (ActiveChat.chatId == incomingChatId) {
        debugPrint('Chat already open. Skip notification.');
        return;
      }
    }
    debugPrint("📩 Foreground message received");
    debugPrint("📩 Data: ${message.data}");

    final title =
        message.data['chefName'] ??
            message.data['title'] ??
            message.notification?.title ??
            "Nearby Hungry";

    final body =
        message.data['message'] ??
            message.data['body'] ??
            message.notification?.body ??
            "New message";

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
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
    debugPrint("📲 Notification opened from background");
    handleNotificationClickFromData(message.data);
  });

  final RemoteMessage? initialMessage =
  await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    debugPrint("🚀 App opened from terminated state");
    handleNotificationClickFromData(initialMessage.data);
  }
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

        // Wait until Firebase restores the session
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user exists → go to Home
        if (snapshot.hasData && snapshot.data != null) {
          return const HomePage();
        }

        // Otherwise → Login
        return const LoginPage();
      },
    );
  }
}