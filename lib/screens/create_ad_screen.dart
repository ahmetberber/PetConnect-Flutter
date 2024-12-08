import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:petconnectflutter/screens/location_picker_screen.dart';

class CreateAdScreen extends StatefulWidget {
  const CreateAdScreen({super.key});

  @override
  _CreateAdScreenState createState() => _CreateAdScreenState();
}

class _CreateAdScreenState extends State<CreateAdScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  LatLng? _selectedLocation;
  String _selectedCategory = "Kayıp";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Yeni İlan Oluştur"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButton<String>(
              value: _selectedCategory,
              items: [
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
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: "Başlık"),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: "Açıklama"),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            Text(
              _selectedLocation != null
                  ? "Konum: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}"
                  : "Konum: Henüz seçilmedi",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              child: Text("Mevcut Konumu Getir"),
            ),
            ElevatedButton(
              onPressed: () async {
                LatLng? newLocation = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationPickerScreen(),
                  ),
                );
                if (newLocation != null) {
                  setState(() {
                    _selectedLocation = newLocation;
                  });
                }
              },
              child: Text("Haritadan Konum Seç"),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _createAd,
              child: Text("İlan Oluştur"),
            ),
          ],
        ),
      ),
    );
  }

  void _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lütfen konum servisini etkinleştirin.")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Konum izni reddedildi.")),
        );
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );

    setState(() {
      _selectedLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _createAd() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Başlık ve açıklama gerekli')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('ads').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': {
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
        },
        'category': _selectedCategory,
        'createdBy': user.uid,
        'createdAt': Timestamp.now(),
        'userId': user.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İlan başarıyla oluşturuldu')),
      );
      Navigator.pop(context);
    }
  }
}
