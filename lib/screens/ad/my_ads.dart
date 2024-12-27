import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:petconnectflutter/screens/ad/edit.dart';
import 'package:petconnectflutter/screens/ad/create.dart';

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
                title: Row(
                  children: [
                    Text(data['title'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    SizedBox(width: 10),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                      decoration: BoxDecoration(
                        color: data['is_active'] ? Colors.green : Colors.red[300],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        data['is_active'] ? 'Yayında' : 'Yayında Değil',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['category'], style: TextStyle(color: Colors.grey[600])),
                    SizedBox(height: 3),
                    Text(data['description'], maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => EditAdScreen(adId: ads[index].id)));
                }
              ),
              );
            },
            );
        },
      ),
    );
  }
}
