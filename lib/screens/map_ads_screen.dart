import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapAdsScreen extends StatefulWidget {
  @override
  _MapAdsScreenState createState() => _MapAdsScreenState();
}

class _MapAdsScreenState extends State<MapAdsScreen> {
  final Set<Marker> _markers = {}; // Harita üzerindeki marker seti
  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  void _loadMarkers() async {
    final snapshot = await FirebaseFirestore.instance.collection('ads').get();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('location')) {
        final position = data['location'] as Map<String, dynamic>;
        final marker = Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(position['latitude'], position['longitude']),
          infoWindow: InfoWindow(
            title: data['title'] ?? 'Başlık Yok',
            snippet: data['description'] ?? 'Açıklama Yok',
          ),
        );
        setState(() {
          _markers.add(marker);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Haritada İlanlar'),
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(41.0122, 28.976), // Başlangıç noktası (Türkiye)
          zoom: 10, // Harita yakınlık seviyesi
        ),
        markers: _markers,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
      ),
    );
  }
}
