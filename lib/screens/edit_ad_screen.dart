import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:petconnectflutter/screens/location_picker_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditAdScreen extends StatefulWidget {
  final String adId;
  final String currentTitle;
  final String currentDescription;
  final String currentCategory;
  final LatLng currentLocation;
  final List<String> currentImages;

  const EditAdScreen({
    Key? key,
    required this.adId,
    required this.currentTitle,
    required this.currentDescription,
    required this.currentCategory,
    required this.currentLocation,
    required this.currentImages,
  }) : super(key: key);

  @override
  _EditAdScreenState createState() => _EditAdScreenState();
}

class _EditAdScreenState extends State<EditAdScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  String _selectedCategory = "Kayıp";
  LatLng? _selectedLocation;
  final List<File> _newImages = [];
  final List<String> _existingImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.currentTitle);
    _descriptionController = TextEditingController(text: widget.currentDescription);
    _selectedCategory = widget.currentCategory;
    _selectedLocation = widget.currentLocation;
    _existingImages.addAll(widget.currentImages);
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _newImages.add(File(pickedFile.path));
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    for (var image in _newImages) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = FirebaseStorage.instance.ref().child('ads/$fileName');
      UploadTask uploadTask = storageRef.putFile(image);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      imageUrls.add(downloadUrl);
    }
    return imageUrls;
  }

  void _removeImage(int index, bool isExisting) {
    setState(() {
      if (isExisting) {
        _existingImages.removeAt(index);
      } else {
        _newImages.removeAt(index);
      }
    });
  }

  void _showImageDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: imagePath.startsWith('http')
            ? CachedNetworkImage(
                imageUrl: imagePath,
                placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Icon(Icons.error),
              )
            : Image.file(File(imagePath)),
      ),
    );
  }

  Future<void> _updateAd() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Başlık ve açıklama gerekli')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    List<String> newImageUrls = await _uploadImages();
    List<String> allImageUrls = [..._existingImages, ...newImageUrls];

    try {
      await FirebaseFirestore.instance.collection('ads').doc(widget.adId).update({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'location': {
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
        },
        'images': allImageUrls,
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

    setState(() {
      _isLoading = false;
    });
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.add_a_photo),
                  label: Text("Fotoğraf Ekle"),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                _existingImages.isNotEmpty || _newImages.isNotEmpty
                    ? Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...List.generate(_existingImages.length, (index) {
                            return Stack(
                              children: [
                                GestureDetector(
                                  onTap: () => _showImageDialog(_existingImages[index]),
                                    child: CachedNetworkImage(
                                    imageUrl: _existingImages[index],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    errorWidget: (context, url, error) => Icon(Icons.error),
                                    ),
                                ),
                                Positioned(
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index, true),
                                    child: Icon(
                                      Icons.remove_circle,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                          ...List.generate(_newImages.length, (index) {
                            return Stack(
                              children: [
                                GestureDetector(
                                  onTap: () => _showImageDialog(_newImages[index].path),
                                  child: Image.file(
                                    _newImages[index],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index, false),
                                    child: Icon(
                                      Icons.remove_circle,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      )
                    : Text("Henüz fotoğraf eklenmedi"),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: "Kategori",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
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
                        TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: "Başlık",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: "Açıklama",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
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
                        ElevatedButton.icon(
                          onPressed: _getCurrentLocation,
                          icon: Icon(Icons.my_location),
                          label: Text("Mevcut Konumu Getir"),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton.icon(
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
                          icon: Icon(Icons.map),
                          label: Text("Haritadan Konum Seç"),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _updateAd,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text("İlanı Güncelle"),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      "İlan güncelleniyor...",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}