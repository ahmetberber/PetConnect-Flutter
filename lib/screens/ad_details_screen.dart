import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
    _fetchOwnerData();
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Kategori: ${widget.category}", style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text("Açıklama:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text(widget.description, style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text("Oluşturulma Tarihi:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text(widget.createdAt, style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            if (_ownerData != null) ...[
              Text("İlan Sahibi:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text("Ad: ${_ownerData!['name']}", style: TextStyle(fontSize: 16)),
              Text("Email: ${_ownerData!['email']}", style: TextStyle(fontSize: 16)),
              Text("Telefon: ${_ownerData!['phone']}", style: TextStyle(fontSize: 16)),
              Text("Adres: ${_ownerData!['address']}", style: TextStyle(fontSize: 16)),
            ],
            SizedBox(height: 8),
            Text("Konum:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: widget.location,
                  zoom: 14,
                ),
                markers: {
                  Marker(
                    markerId: MarkerId("ad-location"),
                    position: widget.location,
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}