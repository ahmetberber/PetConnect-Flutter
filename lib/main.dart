import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyAGIbJGhyQQfHfj6QzTFPrs1LA0Gk0P79U',
      authDomain: 'bitirme-5d4c2.firebaseapp.com',
      projectId: 'bitirme-5d4c2',
      messagingSenderId: '12814231115',
      appId: '1:12814231115:android:a1895fa7494b5370d6cfce',
    ),
  );

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  String? token = await messaging.getToken();
  print('Device Token: $token');

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Message received: ${message.notification?.title}');
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Message clicked!');
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override

  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('PetConnect')),
        body: Center(child: Text('Firebase Başlatıldı')),
      ),
    );
  }
}
