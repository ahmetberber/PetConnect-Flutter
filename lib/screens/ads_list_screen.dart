import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:petconnectflutter/screens/ad_details_screen.dart';

class AdsListScreen extends StatefulWidget {
  const AdsListScreen({super.key});

  @override
  _AdsListScreenState createState() => _AdsListScreenState();
}

class _AdsListScreenState extends State<AdsListScreen> {
  String _searchQuery = "";
  String _selectedCategory = "Tümü";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('İlanlar'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Ara...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                SizedBox(width: 8.0),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      items: ["Tümü", "Kayıp", "Sahiplendirme"].map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('ads').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'Henüz ilan bulunmamaktadır.',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                );
              }

              final ads = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final title = data['title']?.toLowerCase() ?? "";
                final category = data['category'] ?? "";
                final matchesSearch = title.contains(_searchQuery);
                final matchesCategory = _selectedCategory == "Tümü" || category == _selectedCategory;
                return matchesSearch && matchesCategory;
              }).toList();

              if (ads.isEmpty) {
                return Center(child: Text("Hiç ilan bulunamadı."));
              }

              return ListView.builder(
                itemCount: ads.length,
                itemBuilder: (context, index) {
                final ad = ads[index].data() as Map<String, dynamic>;
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                  elevation: 5,
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16.0),
                    title: Text(ad['title'] ?? 'Başlık Yok', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 5),
                        Text(ad['description'] ?? 'Açıklama Yok'),
                        SizedBox(height: 2),
                        Text(ad['createdAt'] != null ? DateFormat('dd/MM/yyyy HH:mm').format(
                            (ad['createdAt'] as Timestamp).toDate()) : '',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    leading: ClipOval(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ad['images'] != null
                            ? CachedNetworkImage(imageUrl: ad['images'][0], fit: BoxFit.cover)
                            : Container(color: Colors.grey[300], child: Icon(Icons.image, size: 40, color: Colors.grey)),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AdDetailsScreen(adId: ads[index].id)),
                      );
                    },
                  ),
                );
                },
              );
              },
            ),
          ),
        ],
      )
    );
  }
}
