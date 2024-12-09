import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:petconnectflutter/screens/location_picker_screen.dart';

class EditAdScreen extends StatefulWidget {
  final String adId;
  final String currentTitle;
  final String currentDescription;
  final String currentCategory;
  final LatLng currentLocation;

  const EditAdScreen({
    Key? key,
    required this.adId,
    required this.currentTitle,
    required this.currentDescription,
    required this.currentCategory,
    required this.currentLocation,
  }) : super(key: key);

  @override
  _EditAdScreenState createState() => _EditAdScreenState();
}

class _EditAdScreenState extends State<EditAdScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  String _selectedCategory = "Kayıp";
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.currentTitle);
    _descriptionController = TextEditingController(text: widget.currentDescription);
    _selectedCategory = widget.currentCategory;
    _selectedLocation = widget.currentLocation;
  }

  Future<void> _updateAd() async {
    try {
      await FirebaseFirestore.instance.collection('ads').doc(widget.adId).update({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'location': {
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
        },
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("İlan başarıyla güncellendi!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: ${e.toString()}")),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("İlanı Güncelle"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: "Başlık"),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: "Açıklama"),
              maxLines: 3,
            ),
            SizedBox(height: 16),
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
                    builder: (context) => LocationPickerScreen(initialLocation: _selectedLocation),
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
              onPressed: _updateAd,
              child: Text("İlanı Güncelle"),
            ),
          ],
        ),
      ),
    );
  }
}