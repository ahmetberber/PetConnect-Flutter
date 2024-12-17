import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';

class AdDetailsScreen extends StatefulWidget {
  final String adId;
  final String category;
  final String title;
  final String description;
  final LatLng location;
  final String createdAt;
  final String ownerId;

  const AdDetailsScreen({
    super.key,
    required this.adId,
    required this.category,
    required this.title,
    required this.description,
    required this.location,
    required this.createdAt,
    required this.ownerId,
  });

  @override
  _AdDetailsScreenState createState() => _AdDetailsScreenState();
}

class _AdDetailsScreenState extends State<AdDetailsScreen> {
  bool _isFavorite = false;
  Map<String, dynamic>? _ownerData;
  List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
    _fetchOwnerData();
    _fetchAdImages();
  }

  Future<void> _checkIfFavorite() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('favorites')
        .doc(uid)
        .get();

    if (doc.exists) {
      List favorites = doc.data()?['adIds'] ?? [];
      setState(() {
        _isFavorite = favorites.contains(widget.adId);
      });
    }
  }

  Future<void> _fetchOwnerData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.ownerId).get();

    if (doc.exists) {
      setState(() {
        _ownerData = doc.data();
      });
    }
  }

  Future<void> _fetchAdImages() async {
    final doc = await FirebaseFirestore.instance.collection('ads').doc(widget.adId).get();

    if (doc.exists) {
      setState(() {
        _imageUrls = List<String>.from(doc.data()?['images'] ?? []);
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = FirebaseFirestore.instance.collection('favorites').doc(uid);
    final doc = await docRef.get();
    if (doc.exists) {
      List favorites = doc.data()?['adIds'] ?? [];

      if (_isFavorite) {
        favorites.remove(widget.adId);
      } else {
        favorites.add(widget.adId);
      }

      await docRef.update({'adIds': favorites});
    } else {
      await docRef.set({'adIds': [widget.adId]});
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("İlan Detayları"),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
              size: 30,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            if (_imageUrls.isNotEmpty)
              CarouselSlider(
                options: CarouselOptions(
                  height: 250,
                  enlargeCenterPage: true,
                  enableInfiniteScroll: false,
                ),
                items: _imageUrls.map((url) {
                    return Container(
                    margin: EdgeInsets.all(5.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Stack(
                        children: [
                          FadeInImage.assetNetwork(
                            placeholder: '',
                            image: url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            fadeInDuration: Duration(milliseconds: 500),
                            imageErrorBuilder: (context, error, stackTrace) {
                              return Center(child: CircularProgressIndicator());
                            },
                            placeholderErrorBuilder: (context, error, stackTrace) {
                              return Center(child: CircularProgressIndicator());
                            },
                          ),
                        ],
                      ),
                    ),
                    );
                }).toList(),
              ),
            SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Açıklama:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    Text(widget.description, style: TextStyle(fontSize: 16)),
                    Text("Oluşturulma Tarihi:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    Text(widget.createdAt, style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            if (_ownerData != null)
              Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                  "İlan Sahibi:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text("Ad Soyad: ${_ownerData!['name']}", style: TextStyle(fontSize: 16)),
                  SizedBox(height: 4),
                  Text("Email: ${_ownerData!['email']}", style: TextStyle(fontSize: 16)),
                  SizedBox(height: 4),
                  Text("Telefon: ${_ownerData!['phone']}", style: TextStyle(fontSize: 16)),
                  SizedBox(height: 4),
                  Text("Adres: ${_ownerData!['address']}", style: TextStyle(fontSize: 16)),
                ],
                ),
              ),
              ),
            SizedBox(height: 16),
            Text(
              "Konum:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: widget.location,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId("ad-location"),
                      position: widget.location,
                    ),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}