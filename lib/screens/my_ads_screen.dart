import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:petconnectflutter/screens/edit_ad_screen.dart';
import 'package:petconnectflutter/screens/create_ad_screen.dart';

class MyAdsScreen extends StatelessWidget {
  const MyAdsScreen({super.key});

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
            return Center(
              child: Text(
                "Hiç ilan oluşturmadınız.",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              )
            );
          }

            return ListView.builder(
            itemCount: ads.length,
            itemBuilder: (context, index) {
              final data = ads[index].data() as Map<String, dynamic>;
              return Card(
              margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(15),
                leading: data['images'] != null ?
                CircleAvatar(
                  radius: 30,
                  backgroundImage: CachedNetworkImageProvider(data['images'][0]),
                  backgroundColor: Colors.transparent,
                ) :
                CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.grey[600],
                  radius: 30,
                  child: Icon(Icons.image),
                ),
                title: Text(
                data['title'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                ),
                subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 5),
                  Text(
                  data['category'],
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                  ),
                  SizedBox(height: 5),
                  Text(
                  data['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  ),
                ],
                ),
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
                        currentLocation: LatLng(data['location']['latitude'], data['location']['longitude']),
                        currentImages: data['images'] != null ? List<String>.from(data['images']) : []
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
              ),
              );
            },
            );
        },
      ),
    );
  }
}
