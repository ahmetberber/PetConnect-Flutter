import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';

const String googleApiKey = "AIzaSyCaCnDZHu-PCM2_UP0J4jodoocMf5mQwoc"; // Google Maps API Key'inizi buraya ekleyin.

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _initialLocation;
  LatLng? _pickedLocation;
  GoogleMapController? _mapController;

  @override
  void initState() {
    _getCurrentLocation();
    super.initState();
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

    setState(() {
      _pickedLocation = newPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Konum Seç"),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _searchPlace, // Arama ikonuna basınca arama yapılır.
          ),
        ],
      ),
      body: _initialLocation != null
          ? Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _initialLocation!,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: (LatLng location) {
                    setState(() {
                      _pickedLocation = location;
                    });
                  },
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  markers: _pickedLocation != null
                      ? {
                          Marker(
                            markerId: MarkerId("selected-location"),
                            position: _pickedLocation!,
                          ),
                        }
                      : {},
                ),
                Positioned(
                  bottom: 30,
                  left: 75,
                  right: 75,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, _pickedLocation);
                    },
                    child: Text("Konum Seç"),
                  ),
                ),
              ],
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
