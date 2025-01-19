import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:petconnectflutter/screens/ad/pick_location.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditAdScreen extends StatefulWidget {
  final String adId;

  const EditAdScreen({super.key, required this.adId});

  @override
  _EditAdScreenState createState() => _EditAdScreenState();
}

class _EditAdScreenState extends State<EditAdScreen> {
  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = "Kayıp";
  LatLng? _selectedLocation;
  final List<File> _newImages = [];
  final List<String> _existingImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _initAd();
  }

  Future<void> _initAd() async {
    final doc = await FirebaseFirestore.instance.collection('ads').doc(widget.adId).get();

    if (doc.exists) {
      final data = doc.data();
      setState(() {
        _titleController = TextEditingController(text: data?['title']);
        _descriptionController = TextEditingController(text: data?['description']);
        _selectedCategory = data?['category'];
        _selectedLocation = LatLng(data?['location']['latitude'], data?['location']['longitude']);
        _existingImages.addAll(List<String>.from(doc.data()?['images'] ?? []));
        _isActive = data?['is_active'];
      });
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
        leading: Icon(Icons.photo_library),
        title: Text('Galeriden Seç'),
        onTap: () async {
          Navigator.pop(context);
          final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
          if (pickedFile != null) {
          setState(() {
            _newImages.add(File(pickedFile.path));
          });
          }
        },
        ),
        ListTile(
        leading: Icon(Icons.camera_alt),
        title: Text('Kamera ile Çek'),
        onTap: () async {
          Navigator.pop(context);
          final pickedFile = await _picker.pickImage(source: ImageSource.camera);
          if (pickedFile != null) {
          setState(() {
            _newImages.add(File(pickedFile.path));
          });
          }
        },
        ),
      ],
      ),
    );
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

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Konum gerekli')),
      );
      return;
    }

    if (_newImages.isEmpty && _existingImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('En az bir fotoğraf gerekli')),
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
                    _existingImages.isNotEmpty || _newImages.isNotEmpty ? Wrap(
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
                    ) : Center(child: Text("Henüz fotoğraf eklenmedi", style: TextStyle(fontSize: 16))),
                    SizedBox(height: 16),
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
                    SizedBox(height: 16),
                    Text(
                      _selectedLocation != null
                        ? "Konum: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}"
                        : "Konum: Henüz seçilmedi",
                      style: TextStyle(fontSize: 16),
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
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      await FirebaseFirestore.instance.collection('ads').doc(widget.adId).update({
                        'is_active': !_isActive,
                      });

                      setState(() {
                        _isActive = !_isActive;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_isActive ? "İlan yayına alındı!" : "İlan yayından kaldırıldı!")),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Hata: ${e.toString()}")),
                      );
                    }

                    setState(() {
                      _isLoading = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isActive ? Colors.red : Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(_isActive ? "Yayından Kaldır" : "Yayına Al"),
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