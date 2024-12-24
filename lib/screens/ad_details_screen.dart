import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:petconnectflutter/screens/chat_screen.dart';

class AdDetailsScreen extends StatefulWidget {
  final String adId;

  const AdDetailsScreen({super.key, required this.adId});

  @override
  _AdDetailsScreenState createState() => _AdDetailsScreenState();
}

class _AdDetailsScreenState extends State<AdDetailsScreen> {
  Map<String, dynamic>? _ownerData;
  List<String> _imageUrls = [];
  String category = '';
  String title = '';
  String description = '';
  LatLng location = LatLng(0, 0);
  String createdAt = '';
  String ownerId = '';
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    _initAdDetails();
  }

  Future<void> _initAdDetails() async {
    await _fetchAdDetails();
  }

  Future<void> _fetchAdDetails() async {
    final doc = await FirebaseFirestore.instance.collection('ads').doc(widget.adId).get();

    if (doc.exists) {
      final data = doc.data();
      setState(() {
        category = data?['category'] ?? '';
        title = data?['title'] ?? '';
        description = data?['description'] ?? '';
        location = LatLng(data?['location']['latitude'] ?? 0, data?['location']['longitude'] ?? 0);
        createdAt = data?['createdAt'] != null ? DateFormat('dd/MM/yyyy HH:mm').format((data?['createdAt'] as Timestamp).toDate()) : '';
        ownerId = data?['userId'] ?? '';
        _imageUrls = List<String>.from(doc.data()?['images'] ?? []);
      });
    }

    final ownerDoc = await FirebaseFirestore.instance.collection('users').doc(ownerId).get();
    if (ownerDoc.exists) {
      setState(() {
        _ownerData = ownerDoc.data();
      });
    }

    setState(() {
      isLoaded = true;
    });
  }


  Future<void> startChat(String currentUserId, String adOwnerId, BuildContext ctx) async {
    final chatRef = FirebaseFirestore.instance.collection('chats');
    final existingChat = await chatRef.where('participants', arrayContains: currentUserId).get();
    String chatId;

    final chat = existingChat.docs.where((doc) => (doc['participants'] as List).any((participant) => participant == adOwnerId)).firstOrNull;
    if (chat != null) {
      chatId = chat.id;
    } else {
      final newChat = await chatRef.add({
        'participants': [currentUserId, adOwnerId],
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      chatId = newChat.id;
    }

    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (context) => ChatScreen(chatId: chatId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("İlan Detayları"),
      ),
      body: !isLoaded ?
      Center(child: CircularProgressIndicator()) :
      SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              Text(title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              if (FirebaseAuth.instance.currentUser?.uid != ownerId)
                ElevatedButton(
                  onPressed: () {
                    startChat(FirebaseAuth.instance.currentUser!.uid, ownerId, context);
                  },
                  child: Text("Mesaj Gönder"),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_imageUrls.isNotEmpty)
              CarouselSlider(
                options: CarouselOptions(height: 300, enlargeCenterPage: true),
                items: _imageUrls.map((url) {
                  return Container(
                    margin: EdgeInsets.all(5.0),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10.0)),
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
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: "Açıklama: ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
                            TextSpan(text: description, style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black)),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: "Oluşturulma Tarihi: ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
                            TextSpan(text: createdAt, style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            if (_ownerData != null)
              SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("İlan Sahibi:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
            ),
            SizedBox(height: 16),
            Text(
              "Konum:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Container(
              height: 300,
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
                    target: location,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId("ad-location"),
                      position: location,
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