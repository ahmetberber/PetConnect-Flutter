import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
                      items: [
                        "Tümü",
                        "Kayıp",
                        "Sahiplendirme",
                      ].map((category) {
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      child: ListTile(
                        title: Text(ad['title'] ?? 'Başlık Yok'),
                        subtitle: Text(ad['description'] ?? 'Açıklama Yok'),
                        leading: Icon(ad['category'] == 'Kayıp'
                            ? Icons.warning
                            : Icons.pets),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                          Text(ad['createdAt'] != null
                            ? DateFormat('dd/MM/yyyy').format(
                              (ad['createdAt'] as Timestamp).toDate())
                            : ''),
                          Text(ad['createdAt'] != null
                            ? DateFormat('HH:mm').format(
                              (ad['createdAt'] as Timestamp).toDate())
                            : ''),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdDetailsScreen(
                                adId: ads[index].id,
                                category: ad["category"],
                                title: ad["title"],
                                description: ad["description"],
                                location: LatLng(ad["location"]["latitude"],
                                ad["location"]["longitude"]),
                                createdAt: DateFormat('dd/MM/yyyy HH:mm')
                                .format((ad['createdAt'] as Timestamp)
                                    .toDate()),
                                ownerId: ad["userId"] ?? '',
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
          ),
        ],
      )
    );
  }
}
