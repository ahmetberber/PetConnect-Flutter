import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:petconnectflutter/screens/ad_details_screen.dart';
import 'package:petconnectflutter/screens/create_ad_screen.dart';

class AdsListScreen extends StatelessWidget {
  const AdsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('İlanlar'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_box, size: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateAdScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ads') // Firestore'daki 'ads' koleksiyonundan veri akışı
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Henüz ilan bulunmamaktadır.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }

          final ads = snapshot.data!.docs;

          return ListView.builder(
            itemCount: ads.length,
            itemBuilder: (context, index) {
              final ad = ads[index].data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(ad['title'] ?? 'Başlık Yok'),
                  subtitle: Text(ad['description'] ?? 'Açıklama Yok'),
                  trailing: Text(ad['createdAt'] != null ? DateFormat('dd/MM/yyyy HH:mm').format((ad['createdAt'] as Timestamp).toDate()) : ''),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdDetailsScreen(
                          adId: ads[index].id,
                          title: ad["title"],
                          description: ad["description"],
                          location: LatLng(ad["location"]["latitude"], ad["location"]["longitude"]),
                          createdAt: DateFormat('dd/MM/yyyy HH:mm').format((ad['createdAt'] as Timestamp).toDate()),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
