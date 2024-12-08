import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:petconnectflutter/screens/edit_ad_screen.dart';
import 'package:petconnectflutter/screens/create_ad_screen.dart';

class MyAdsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text("İlanlarım"),
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
            .collection('ads')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final ads = snapshot.data!.docs;

          if (ads.isEmpty) {
            return Center(child: Text("Hiç ilan oluşturmadınız."));
          }

          return ListView.builder(
            itemCount: ads.length,
            itemBuilder: (context, index) {
              final data = ads[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['title']),
                subtitle: Text(data['category']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                    children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                        builder: (context) => EditAdScreen(
                          adId: ads[index].id,
                          currentTitle: data['title'],
                          currentDescription: data['description'],
                          currentCategory: data['category'],
                          currentLocation: LatLng(data['location']['latitude'], data['location']['longitude'])
                        ),
                        ),
                      );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                      final confirmDelete = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                        title: Text("İlanı Sil"),
                        content: Text("Bu ilanı silmek istediğinizden emin misiniz?"),
                        actions: [
                          TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text("Hayır"),
                          ),
                          TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text("Evet"),
                          ),
                        ],
                        ),
                      );

                      if (confirmDelete) {
                        await FirebaseFirestore.instance.collection('ads').doc(ads[index].id).delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("İlan silindi.")),
                        );
                      }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
