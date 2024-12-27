import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petconnectflutter/screens/chat/list.dart';
import 'package:petconnectflutter/screens/chat/detail.dart';
import 'package:petconnectflutter/screens/ad/my_ads.dart';
import 'screens/auth/login.dart';
import 'screens/home.dart';
import 'screens/auth/register.dart';
import 'screens/ad/create.dart';
import 'screens/ad/list.dart';
import 'screens/ad/map.dart';
import 'screens/profile.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void _setupLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_launcher_foreground');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

void _setupFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("Bildirim izni verildi!");
  } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
    print("Bildirim izni reddedildi.");
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    _showNotification(message.notification?.title, message.notification?.body);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleMessage(message);
  });
}

void _handleMessage(RemoteMessage message) {
  if (message.data['chatId'] != null) {
    navigatorKey.currentState?.pushNamed('/chat', arguments: {'chatId': message.data['chatId']});
  }
}

void _showNotification(String? title, String? body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'your_channel_id',
    'your_channel_name',
    importance: Importance.high,
    priority: Priority.high,
  );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(1, title, body, platformChannelSpecifics);
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  _showNotification(message.notification?.title, message.notification?.body);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  _setupLocalNotifications();
  _setupFirebaseMessaging();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetConnect',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => AuthenticationWrapper(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/chats': (context) => ChatListScreen(),
        '/chat': (context) => ChatScreen(chatId: ':chatId'),
        '/createAd': (context) => CreateAdScreen(),
        '/ads': (context) => AdsListScreen(),
        '/myAds': (context) => MyAdsScreen(),
        '/mapAds': (context) => MapAdsScreen(),
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Eğer kullanıcı giriş yaptıysa HomeScreen'e yönlendir
        if (snapshot.hasData && snapshot.data != null) {
          return HomeScreen();
        } else {
          // Giriş yapılmadıysa LoginScreen'e yönlendir
          return LoginScreen();
        }
      },
    );
  }
}
