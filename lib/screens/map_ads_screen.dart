import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_webservice/places.dart';

const String googleApiKey = "AIzaSyCaCnDZHu-PCM2_UP0J4jodoocMf5mQwoc";

class MapAdsScreen extends StatefulWidget {
  const MapAdsScreen({super.key});

  @override
  _MapAdsScreenState createState() => _MapAdsScreenState();
}

class _MapAdsScreenState extends State<MapAdsScreen> {
  final Set<Marker> _markers = {};
  late GoogleMapController? _mapController;
  bool _isLoading = true;

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
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _searchPlace() async {
    Prediction? prediction = await PlacesAutocomplete.show(
      offset: 0,
      radius: 1000,
      types: [],
      strictbounds: false,
      region: "tr",
      context: context,
      apiKey: googleApiKey,
      mode: Mode.overlay,
      language: "tr",
      components: [Component(Component.country, "tr")]
    );

    if (prediction != null) {
      _moveToPlace(prediction);
    }
  }

  Future<void> _moveToPlace(Prediction prediction) async {
    GoogleMapsPlaces places = GoogleMapsPlaces(apiKey: googleApiKey);
    PlacesDetailsResponse detail = await places.getDetailsByPlaceId(prediction.placeId!);

    final lat = detail.result.geometry!.location.lat;
    final lng = detail.result.geometry!.location.lng;
    final newPosition = LatLng(lat, lng);

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(newPosition),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Harita'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _searchPlace,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(41.0122, 28.976),
              zoom: 11,
            ),
            markers: _markers,
            onMapCreated: (controller) => _mapController = controller,
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
