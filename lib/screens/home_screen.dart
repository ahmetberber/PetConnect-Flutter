import 'package:flutter/material.dart';
import 'ads_list_screen.dart';
import 'map_ads_screen.dart';
import 'profile_screen.dart';
import 'create_ad_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Alt sekmelerde gösterilecek ekranlar
  static final List<Widget> _widgetOptions = <Widget>[
    AdsListScreen(), // İlanlar Listesi
    MapAdsScreen(),  // Haritada İlanlar
    ProfileScreen(), // Kullanıcı Profili
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
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Bildirim sayfasına yönlendirme yapılabilir
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Bildirimler özelliği yakında!')),
              );
            },
          ),
        ],
      ),
      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'İlanlar',
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
        onTap: _onItemTapped,
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (context) => CreateAdScreen()),
      //     );
      //   },
      //   child: Icon(Icons.add),
      //   tooltip: 'Yeni İlan Oluştur',
      // ),
    );
  }
}
