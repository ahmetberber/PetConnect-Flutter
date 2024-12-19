import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:intl/intl.dart';
import 'package:petconnectflutter/screens/ad_details_screen.dart';

const String googleApiKey = "AIzaSyCaCnDZHu-PCM2_UP0J4jodoocMf5mQwoc";

class MapAdsScreen extends StatefulWidget {
  const MapAdsScreen({super.key});

  @override
  _MapAdsScreenState createState() => _MapAdsScreenState();
}

class _MapAdsScreenState extends State<MapAdsScreen> {
  LatLng? _initialLocation;
  final Set<Marker> _markers = {};
  late GoogleMapController? _mapController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMarkers();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
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
      _initialLocation = LatLng(position.latitude, position.longitude);
    });
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdDetailsScreen(
                    adId: doc.id,
                    category: doc["category"],
                    title: doc["title"],
                    description: doc["description"],
                    location: LatLng(doc["location"]["latitude"],
                    doc["location"]["longitude"]),
                    createdAt: DateFormat('dd/MM/yyyy HH:mm').format((doc['createdAt'] as Timestamp)
                      .toDate()),
                    ownerId: doc["userId"] ?? '',
                  ),
                ),
              );
            },
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
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
      components: [Component(Component.country, "tr")],
      logo: Container(height: 0),
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
      body: _initialLocation != null
        ? Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _initialLocation!,
                  zoom: 14,
                ),
                markers: _markers,
                onMapCreated: (controller) => _mapController = controller,
              ),
              if (_isLoading)
                Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          )
        : Center(child: CircularProgressIndicator()),
    );
  }
}
