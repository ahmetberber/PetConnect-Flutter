import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:petconnectflutter/screens/my_ads_screen.dart';
import 'ads_list_screen.dart';
import 'map_ads_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
  }

  void _setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("Bildirim izni verildi!");
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print("Bildirim izni reddedildi.");
    }

    String? token = await messaging.getToken();
    print("Firebase Token: $token");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Bir bildirim alındı: ${message.notification?.title}");
      _showNotification(message.notification?.title, message.notification?.body);
    });
  }

  void _showNotification(String? title, String? body) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$title: $body")),
    );
  }


  static final List<Widget> _widgetOptions = <Widget>[
    AdsListScreen(),
    MyAdsScreen(),
    MapAdsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PetConnect'),
      ),
      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              spreadRadius: 0,
              blurRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.list),
                label: 'İlanlar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment),
                label: 'İlanlarım',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map),
                label: 'Harita',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            onTap: _onItemTapped,
            backgroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
