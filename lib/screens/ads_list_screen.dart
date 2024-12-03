import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdsListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('İlanlar'),
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
                  trailing: Text(
                    ad['createdAt'] != null
                        ? (ad['createdAt'] as Timestamp).toDate().toString()
                        : '',
                  ),
                  onTap: () {
                    // İlan detay sayfasına yönlendirme (Geliştirilecek)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${ad['title']} seçildi!')),
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
