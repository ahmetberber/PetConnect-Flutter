import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class CreateAdScreen extends StatefulWidget {
  @override
  _CreateAdScreenState createState() => _CreateAdScreenState();
}

class _CreateAdScreenState extends State<CreateAdScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  Position? _currentPosition;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Konum servisleri etkin değil')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Konum izinleri kalıcı olarak reddedildi')),
        );
        return;
      }
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _currentPosition = position;
    });
  }

  Future<void> _createAd() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Başlık ve açıklama gerekli')),
      );
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Konum alınamadı')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('ads').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': {
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
        },
        'createdBy': user.uid,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İlan başarıyla oluşturuldu')),
      );
      Navigator.pop(context);
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yeni İlan Oluştur'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Başlık',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Açıklama',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            _currentPosition == null
                ? Text('Konum alınıyor...')
                : Text(
                    'Konum: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}'),
            SizedBox(height: 16),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _createAd,
                    child: Text('İlan Oluştur'),
                  ),
          ],
        ),
      ),
    );
  }
}
